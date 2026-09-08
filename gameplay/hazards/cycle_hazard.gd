class_name CycleHazard
extends DeathZone
## Shared phase clock. Collision volume stays reserved for conservative spawn validation.

enum State { INACTIVE, TELEGRAPH, ACTIVE }
var state: State = State.INACTIVE
var elapsed_ticks: int = 0
var tuning: HazardCycleConfig
var permanent: bool = false
var spike_visual: bool = false
var triggered_mode: bool = false
var trigger_requested: bool = false
var _trigger_ticks: int = 0


func _ready() -> void:
	super._ready()
	if tuning == null or not tuning.validate():
		push_error("Invalid hazard config")
		hide()
		lethal = false
		set_physics_process(false)
		return
	var shape := RectangleShape2D.new()
	shape.size = tuning.size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	elapsed_ticks = PlayerMovementConfig.ticks(tuning.phase_offset)
	update_phase()


func set_trigger(active: bool) -> void:
	# Local switch contract: rising edge warns, held true stays active, false retracts.
	if active != trigger_requested:
		_trigger_ticks = 0
	trigger_requested = active


func update_phase() -> void:
	var warning: int = maxi(1, PlayerMovementConfig.ticks(tuning.telegraph_duration))
	if permanent:
		state = State.ACTIVE
	elif triggered_mode:
		state = State.INACTIVE if not trigger_requested else (
			State.TELEGRAPH if _trigger_ticks < warning else State.ACTIVE)
	else:
		var rest: int = PlayerMovementConfig.ticks(tuning.inactive_duration)
		var active: int = maxi(1, PlayerMovementConfig.ticks(tuning.active_duration))
		var phase: int = elapsed_ticks % (rest + warning + active)
		state = State.INACTIVE if phase < rest else (
			State.TELEGRAPH if phase < rest + warning else State.ACTIVE)
	lethal = state == State.ACTIVE
	queue_redraw()


func _physics_process(delta: float) -> void:
	update_phase()
	super._physics_process(delta)
	elapsed_ticks += 1
	if trigger_requested:
		_trigger_ticks += 1


func _draw() -> void:
	if tuning == null:
		return
	var tint := Color("ef394f") if lethal else Color("ffbf47")
	if state == State.INACTIVE:
		tint = Color(0.4, 0.5, 0.6, 0.25)
	var rect := Rect2(-tuning.size / 2, tuning.size)
	if spike_visual:
		var count: int = maxi(1, ceili(tuning.size.x / 20))
		var width: float = tuning.size.x / count
		for index: int in count:
			var x: float = rect.position.x + index * width
			draw_colored_polygon(PackedVector2Array([Vector2(x, rect.end.y),
				Vector2(x + width / 2, rect.position.y), Vector2(x + width, rect.end.y)]), tint)
	else:
		draw_rect(rect, tint, lethal, -1.0 if lethal else 2.0)
