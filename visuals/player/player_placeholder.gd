class_name PlayerPlaceholder
extends Node2D
## Procedural robot placeholder, with no squash/stretch or final-art dependency.

@export var local_indicator: bool = true
var animation := PlayerAnimationMachine.new()
var _facing: float = 1.0
var _dash: Vector2 = Vector2.ZERO
var _selection: Vector2 = Vector2.ZERO
var _body_color := Color("48bedb")
var _accent := Color("b6ffdc")
var _max_speed: bool = false
var _invulnerable: bool = false


func present(motor: PlayerMotor, selection: Vector2) -> void:
	animation.advance(motor)
	if absf(motor.velocity.x) > 1.0:
		_facing = signf(motor.velocity.x)
	if motor.machine.current == PlayerStateMachine.State.WALL_SLIDE:
		# The collision adapter supplies wall-facing independently of horizontal motion.
		_facing = -motor.wall_side if motor.wall_side != 0 else _facing
	_dash = motor.dash_vector
	_selection = selection
	_max_speed = absf(motor.velocity.x) >= motor.config.ground_max_speed * 0.98
	_invulnerable = motor.invulnerability_ticks > 0
	_body_color = Color("48bedb") if motor.double_jump_available else Color("687e91")
	_accent = Color("b6ffdc") if motor.dash_available else Color("536777")
	queue_redraw()


func _draw() -> void:
	var color: Color = _body_color
	if animation.current == PlayerAnimationMachine.Pose.DEATH:
		color = Color("d07088")
	if _invulnerable:
		color.a = 0.65 + 0.2 * sin(animation.phase * 2.0)
	if animation.current == PlayerAnimationMachine.Pose.DASH:
		draw_set_transform(Vector2.ZERO, _dash.angle() + PI / 2.0)
	draw_rect(Rect2(-16, -27, 32, 43), color)
	draw_rect(Rect2(-14, -32, 28, 14), Color("d5ebef"))
	draw_rect(Rect2(_facing * 5 - 5, -29, 10, 5), _accent)
	var stride: float = sin(animation.phase) * 5.0 if animation.current == PlayerAnimationMachine.Pose.RUN else 0.0
	draw_line(Vector2(-9, 12), Vector2(-9 + stride, 30), color, 8.0)
	draw_line(Vector2(9, 12), Vector2(9 - stride, 30), color, 8.0)
	draw_set_transform(Vector2.ZERO)
	if animation.current == PlayerAnimationMachine.Pose.DOUBLE_JUMP:
		draw_arc(Vector2.ZERO, 42, 0, TAU, 24, Color("b58aff"), 4.0)
	if animation.current == PlayerAnimationMachine.Pose.DASH:
		draw_line(-_dash * 22, -_dash * 75, Color(0.35, 0.9, 1.0, 0.5), 14.0)
	if animation.current in [PlayerAnimationMachine.Pose.SKID, PlayerAnimationMachine.Pose.TURNAROUND]:
		draw_line(Vector2(-_facing * 22, 29), Vector2(-_facing * 45, 29), _accent, 3.0)
	if animation.current == PlayerAnimationMachine.Pose.FINISH_VICTORY:
		draw_arc(Vector2(0, -42), 12, PI, TAU, 8, Color.GOLD, 4.0)
	if _max_speed:
		draw_rect(Rect2(-18, -34, 36, 66), _accent, false, 1.5)
	if local_indicator and not _selection.is_zero_approx():
		var end: Vector2 = _selection * 55
		draw_line(_selection * 38, end, Color.WHITE, 2.0)
		draw_line(end, end - _selection.rotated(0.55) * 9, Color.WHITE, 2.0)
		draw_line(end, end - _selection.rotated(-0.55) * 9, Color.WHITE, 2.0)
