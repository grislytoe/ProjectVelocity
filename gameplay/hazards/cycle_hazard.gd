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
	var previous_state: State = state
	var previous_lethal: bool = lethal
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
	# Phase visuals are static between transitions; avoid rebuilding the same geometry at 60 Hz.
	if state != previous_state or lethal != previous_lethal:
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
	var tint := ArtPalette.DANGER if lethal else ArtPalette.WARNING
	if state == State.INACTIVE:
		tint = Color(ArtPalette.STEEL.r, ArtPalette.STEEL.g, ArtPalette.STEEL.b, 0.34)
	var rect := Rect2(-tuning.size / 2, tuning.size)
	if spike_visual:
		var count: int = maxi(1, ceili(tuning.size.x / 20))
		var width: float = tuning.size.x / count
		for index: int in count:
			var x: float = rect.position.x + index * width
			var points := PackedVector2Array([Vector2(x, rect.end.y),
				Vector2(x + width / 2, rect.position.y), Vector2(x + width, rect.end.y)])
			if state == State.ACTIVE:
				draw_colored_polygon(points, tint)
			var contour := points.duplicate()
			contour.append(points[0])
			draw_polyline(contour, tint if state != State.ACTIVE else Color.WHITE, 2, true)
		draw_line(Vector2(rect.position.x, rect.end.y), rect.end, ArtPalette.DANGER_DARK, 4, true)
	else:
		# Lasers use end caps and a bright core; telegraph is a hollow channel.
		var horizontal: bool = tuning.size.x >= tuning.size.y
		var axis_start := Vector2(rect.position.x, 0) if horizontal else Vector2(0, rect.position.y)
		var axis_end := Vector2(rect.end.x, 0) if horizontal else Vector2(0, rect.end.y)
		var thickness: float = minf(tuning.size.x, tuning.size.y)
		draw_line(axis_start, axis_end, tint, thickness if lethal else 3.0, true)
		if lethal:
			draw_line(axis_start, axis_end, Color(1, 0.88, 0.82, 0.8), maxf(2.0, thickness * 0.18), true)
		var cap := Vector2(0, thickness * 0.72) if horizontal else Vector2(thickness * 0.72, 0)
		draw_line(axis_start - cap, axis_start + cap, tint, 4, true)
		draw_line(axis_end - cap, axis_end + cap, tint, 4, true)
		if state == State.TELEGRAPH:
			for ratio: float in [0.25, 0.5, 0.75]:
				var marker := axis_start.lerp(axis_end, ratio)
				draw_circle(marker, 3.0, ArtPalette.WARNING)
