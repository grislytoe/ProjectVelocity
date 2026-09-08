class_name SoloTrial
extends Node
## Fixed tick orchestration; lifecycle exclusively authorizes progress and Finish.

signal changed
signal message(key: String)
enum Phase { HINT, COUNTDOWN, RUN, RESULT }
var phase: Phase = Phase.HINT
var course: SoloCourse
var layer: InputLayer
var records: TrialRecords
var barrier: StartBarrier
var tick: int = 0
var elapsed: int = 0
var hint_ticks: int = 180
var hold_ticks: int = 0
var restart_latched: bool = false
var deaths: int = 0
var valid: bool = true
var splits: Array[int] = []
var result: Dictionary = {}
var baseline: Dictionary = {}
var live_delta: String = ""
var _retry_pending: bool = false
var _frame := InputFrame.new()

func _ready() -> void:
	process_physics_priority = -100
	retry(true)

func retry(show_hint: bool = false) -> void:
	# Executed before physics, never inside an Area's query-flush callback.
	if is_instance_valid(course):
		course.free()
	if is_instance_valid(barrier):
		barrier.free()
	layer.clear_transient_state(true)
	_frame = InputFrame.new()
	course = load(records.definition.scene_path).instantiate() as SoloCourse
	course.input_layer = layer
	course.definition = records.definition
	add_child(course)
	course.player.input_provider = func() -> InputFrame: return _frame
	course.lifecycle.checkpoint_activated.connect(_checkpoint)
	course.lifecycle.completed.connect(_finish)
	course.lifecycle.notification.connect(func(key: String) -> void: message.emit(key))
	course.player.died.connect(_death)
	course.player.gameplay_manipulated.connect(invalidate)
	barrier = StartBarrier.new()
	add_child(barrier)
	barrier.arm([course.player], [&"local"])
	tick = 0
	elapsed = 0
	deaths = 0
	valid = true
	splits.clear()
	result.clear()
	live_delta = ""
	baseline = records.best()
	hint_ticks = 180
	hold_ticks = 0
	phase = Phase.HINT
	if not show_hint:
		dismiss_hint()
	changed.emit()

func dismiss_hint() -> void:
	if phase != Phase.HINT:
		return
	phase = Phase.COUNTDOWN
	layer.clear_transient_state(true)
	barrier.gate.set_ready(&"local", true)
	barrier.gate.schedule(tick + 180, tick)
	changed.emit()

func request_retry() -> void:
	_retry_pending = true

func _physics_process(_delta: float) -> void:
	if _retry_pending:
		_retry_pending = false
		retry()
	tick += 1
	_frame = layer.sample()
	if not _frame.restart_held:
		restart_latched = false
		hold_ticks = 0
	elif not restart_latched and phase != Phase.RESULT:
		hold_ticks += 1
		if hold_ticks >= 30:
			restart_latched = true
			retry()
			return
	if phase == Phase.HINT:
		hint_ticks -= 1
		if hint_ticks <= 0:
			dismiss_hint()
	elif phase == Phase.COUNTDOWN:
		if barrier.advance(tick):
			phase = Phase.RUN
			elapsed = 0
			changed.emit()
	elif phase == Phase.RUN:
		elapsed += 1
		if elapsed > TrialRecord.MAX_TICKS:
			invalidate()

func invalidate() -> void:
	valid = false
	changed.emit()

func _death() -> void:
	if phase == Phase.RUN:
		deaths += 1

func _checkpoint(id: StringName) -> void:
	if phase != Phase.RUN:
		return
	var index: int = records.definition.checkpoint_ids.find(id)
	if index != splits.size():
		invalidate()
		return
	splits.append(elapsed)
	live_delta = "" if baseline.is_empty() else TrialRecord.delta(elapsed - int(baseline.splits[index]))
	changed.emit()

func _finish() -> void:
	if phase != Phase.RUN:
		return
	phase = Phase.RESULT
	course.world.retire_target(&"local")
	result = records.complete(elapsed, splits, valid)
	course.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	changed.emit()
