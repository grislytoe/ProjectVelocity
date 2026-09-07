class_name PlayerPlaceholder
extends Node2D
## Modular vector robot. Optional observer; deleting it must not affect movement.

@export var is_local: bool = true:
	set(value):
		is_local = value
		refresh_style()
@export var local_indicator: bool = true
@export var presentation_config: CharacterPresentationConfig = preload("res://visuals/player/default_presentation.tres")
var animation := PlayerAnimationMachine.new()
var appearance := RobotAppearance.new()
var parts: Dictionary = {}
var rig: Node2D
var nickname_label: Label
var selected_direction: Vector2 = Vector2.ZERO
var dash_direction: Vector2 = Vector2.RIGHT
var jump_ready: bool = true
var dash_ready: bool = true
var _facing: float = 1.0
var _max_speed: bool = false
var _invulnerable: bool = false


func _ready() -> void:
	if presentation_config == null or not presentation_config.valid():
		presentation_config = CharacterPresentationConfig.new()
	rig = Node2D.new()
	rig.name = "Modules"
	add_child(rig)
	for module: String in ["head", "torso", "left_arm", "right_arm", "left_leg", "right_leg", "hat"]:
		var part := RobotPart.new()
		part.name = module.to_pascal_case()
		part.size = Vector2(7, 18)
		if module == "head":
			part.size = Vector2(26, 17)
			part.visor = true
		elif module == "torso":
			part.size = Vector2(26, 24)
		elif module == "hat":
			part.size = Vector2(24, 5)
		parts[module] = part
		rig.add_child(part)
	# Attachment reserved for future registered assets; unknown IDs use base modules.
	parts.hat.visible = false
	nickname_label = Label.new()
	nickname_label.name = "OpponentNickname"
	nickname_label.position = Vector2(-120, -59)
	nickname_label.size = Vector2(240, 22)
	nickname_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nickname_label.add_theme_font_size_override("font_size", 16)
	add_child(nickname_label)
	refresh_style()
	pose_modules()


func apply_profile(profile: PlayerProfileData) -> bool:
	var result: RobotAppearance = RobotAppearance.from_profile(profile)
	if result == null:
		return false
	appearance = result
	refresh_style()
	return true


func refresh_style() -> void:
	if not is_inside_tree() or nickname_label == null:
		return
	modulate = Color(1, 1, 1, 1.0 if is_local else presentation_config.opponent_opacity)
	nickname_label.text = appearance.nickname
	nickname_label.visible = not is_local
	for module: String in parts:
		var part: RobotPart = parts[module]
		part.body_color = appearance.body_color
		part.accent_color = appearance.accent_color
		part.outline_width = presentation_config.local_outline_width if is_local else presentation_config.opponent_outline_width
		part.outline_color = presentation_config.outline_color
		part.queue_redraw()
	if not is_local:
		selected_direction = Vector2.ZERO
	queue_redraw()


func present(frame: PlayerVisualFrame, selection: Vector2 = Vector2.ZERO) -> void:
	animation.advance(frame)
	if absf(frame.velocity.x) > 1:
		_facing = signf(frame.velocity.x)
	if frame.state == PlayerStateMachine.State.WALL_SLIDE and frame.wall_side != 0:
		_facing = -frame.wall_side
	dash_direction = frame.dash_vector
	selected_direction = selection if is_local and local_indicator else Vector2.ZERO
	if frame.state in [PlayerStateMachine.State.DASH, PlayerStateMachine.State.DEATH,
		PlayerStateMachine.State.RESPAWN, PlayerStateMachine.State.FINISH]:
		selected_direction = Vector2.ZERO
	jump_ready = frame.jump_ready
	dash_ready = frame.dash_ready
	_max_speed = frame.speed_ratio >= 0.98
	_invulnerable = frame.invulnerable
	if is_inside_tree() and rig != null:
		pose_modules()
	queue_redraw()


func pose_modules() -> void:
	var stride: float = sin(animation.phase)
	var pose: PlayerAnimationMachine.Pose = animation.current
	var arm_angle: float = 0.08 * stride
	var leg_angle: float = 0.0
	var lean: float = 0.0
	var lift: float = 0.0
	match pose:
		PlayerAnimationMachine.Pose.RUN:
			arm_angle = stride * 0.8
			leg_angle = -stride * 0.65
			lean = 0.12 * _facing
		PlayerAnimationMachine.Pose.JUMP:
			arm_angle = 1.8
			leg_angle = 0.45
		PlayerAnimationMachine.Pose.FALL, PlayerAnimationMachine.Pose.FAST_FALL_RESERVED:
			arm_angle = 0.95
			leg_angle = 0.2
		PlayerAnimationMachine.Pose.DOUBLE_JUMP:
			arm_angle = 2.3
			leg_angle = 0.7
			lean = TAU * animation.age_ticks / 11.0 * _facing
		PlayerAnimationMachine.Pose.WALL_SLIDE:
			arm_angle = 1.2
			lean = 0.22 * _facing
		PlayerAnimationMachine.Pose.WALL_JUMP:
			arm_angle = 2.0
			leg_angle = 0.85
			lean = -0.3 * _facing
		PlayerAnimationMachine.Pose.DASH:
			arm_angle = 0.12
			lean = dash_direction.angle() + PI / 2
		PlayerAnimationMachine.Pose.LANDING:
			leg_angle = 0.6
			lift = 4.0
		PlayerAnimationMachine.Pose.SKID:
			lean = -0.35 * _facing
			leg_angle = 0.45
		PlayerAnimationMachine.Pose.TURNAROUND:
			lean = 0.3 * _facing
			arm_angle = 0.8
		PlayerAnimationMachine.Pose.FINISH_VICTORY:
			arm_angle = 2.65
			leg_angle = 0.15
		PlayerAnimationMachine.Pose.RESPAWN:
			arm_angle = 1.4 * maxf(0, 1.0 - animation.age_ticks / 15.0)
	rig.rotation = lean
	parts.head.position = Vector2(0, -23 + lift)
	parts.torso.position = Vector2(0, -3 + lift)
	parts.left_arm.position = Vector2(-19, -1 + lift)
	parts.right_arm.position = Vector2(19, -1 + lift)
	parts.left_leg.position = Vector2(-8, 22)
	parts.right_leg.position = Vector2(8, 22)
	parts.hat.position = Vector2(0, -34 + lift)
	parts.left_arm.rotation = arm_angle
	parts.right_arm.rotation = -arm_angle
	parts.left_leg.rotation = leg_angle
	parts.right_leg.rotation = -leg_angle
	parts.head.rotation = 0.08 * _facing
	parts.torso.rotation = 0
	parts.hat.rotation = 0
	var scatter: float = clampf(animation.age_ticks / 27.0, 0, 1) if pose == PlayerAnimationMachine.Pose.DEATH else 0.0
	for module: String in parts:
		var part: RobotPart = parts[module]
		if scatter > 0:
			part.position += part.position.normalized() * scatter * 38
			part.rotation += scatter * (1.0 if part.position.x >= 0 else -1.0)
		part.modulate.a = 1.0 - scatter
		part.emission = 1.0 if dash_ready else 0.12
		if "leg" in module:
			part.emission = 1.0 if jump_ready else 0.12
		part.queue_redraw()


func _draw() -> void:
	if nickname_label == null:
		return
	var accent: Color = appearance.accent_color
	accent.a = presentation_config.effect_intensity
	var pose: PlayerAnimationMachine.Pose = animation.current
	if pose == PlayerAnimationMachine.Pose.DOUBLE_JUMP:
		draw_arc(Vector2.ZERO, 35 + animation.age_ticks, 0, TAU, 40, accent, 2, true)
	if pose == PlayerAnimationMachine.Pose.DASH:
		draw_line(-dash_direction * 28, -dash_direction * 76, accent, 5, true)
	if pose in [PlayerAnimationMachine.Pose.SKID, PlayerAnimationMachine.Pose.TURNAROUND]:
		draw_line(Vector2(-_facing * 20, 31), Vector2(-_facing * 43, 31), accent, 2, true)
	if pose == PlayerAnimationMachine.Pose.RESPAWN or _invulnerable:
		draw_arc(Vector2.ZERO, 37, 0, TAU, 40, accent, 1, true)
	if _max_speed and pose == PlayerAnimationMachine.Pose.RUN:
		draw_line(Vector2(-_facing * 23, 5), Vector2(-_facing * 39, 5), accent, 1.5, true)
	# Shape cues remain legible independently of user-selected color hues.
	if pose != PlayerAnimationMachine.Pose.DEATH:
		draw_circle(Vector2(-8, 35), 2.5, Color.WHITE, jump_ready, -1 if jump_ready else 1, true)
		draw_rect(Rect2(5, 32.5, 5, 5), Color.WHITE, dash_ready, -1 if dash_ready else 1)
	if is_local and local_indicator and not selected_direction.is_zero_approx():
		var end: Vector2 = selected_direction * 55
		var arrow_color: Color = Color.WHITE if dash_ready else Color(0.6, 0.65, 0.7)
		draw_line(selected_direction * 39, end, arrow_color, 2, true)
		draw_line(end, end - selected_direction.rotated(0.55) * 9, arrow_color, 2, true)
		draw_line(end, end - selected_direction.rotated(-0.55) * 9, arrow_color, 2, true)
