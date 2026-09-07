class_name PlayerController
extends CharacterBody2D
## Collision adapter. All movement intent comes from an injected M2 layer or test provider.

signal dash_started
signal double_jumped

@export var movement_config: PlayerMovementConfig = preload("res://gameplay/player/default_movement.tres")
@export var simulation_enabled: bool = true
var input_layer: InputLayer
var input_provider: Callable
var motor: PlayerMotor
var spawn_position: Vector2
var contacts := MovementContacts.new()
var _neutral := InputFrame.new()
var _left_probe := KinematicCollision2D.new()
var _right_probe := KinematicCollision2D.new()
var _down_probe := KinematicCollision2D.new()
var _relocated: bool = true

@onready var presentation: PlayerPlaceholder = $Presentation


func _ready() -> void:
	if not movement_config.validate() or Engine.physics_ticks_per_second != PlayerMovementConfig.PHYSICS_HZ:
		push_error("PlayerController requires valid tuning and 60 Hz physics")
		set_physics_process(false)
		return
	motor = PlayerMotor.new(movement_config)
	spawn_position = global_position
	up_direction = Vector2.UP
	floor_max_angle = deg_to_rad(movement_config.slope_slide_angle_degrees)
	floor_snap_length = movement_config.floor_snap_distance
	floor_stop_on_slope = true
	floor_constant_speed = true


func _physics_process(_delta: float) -> void:
	if not simulation_enabled:
		return
	var frame: InputFrame = _neutral
	if input_provider.is_valid():
		frame = input_provider.call() as InputFrame
	elif input_layer != null:
		frame = input_layer.sample()
	if frame == null:
		frame = _neutral
	advance(frame)


func advance(frame: InputFrame) -> void:
	collect_contacts()
	motor.step(frame, contacts)
	velocity = motor.velocity
	if not motor.machine.locked():
		move_and_slide()
	motor.velocity = velocity
	_relocated = false
	collect_contacts()
	motor.classify(contacts)
	var selected: Vector2 = frame.dash_direction
	if motor.events & PlayerMotor.Event.DASH_STARTED:
		clear_selection()
		selected = Vector2.ZERO
		dash_started.emit()
	if motor.events & PlayerMotor.Event.DOUBLE_JUMPED:
		double_jumped.emit()
	if motor.machine.locked():
		selected = Vector2.ZERO
	presentation.present(motor, selected)


func collect_contacts() -> void:
	contacts.clear()
	if not _relocated:
		contacts.grounded = is_on_floor() and velocity.y >= 0.0
		for index: int in get_slide_collision_count():
			accept_normal(get_slide_collision(index).get_normal())
	# Probes retain ordinary wall contact even without input pushing into the wall.
	var distance: float = movement_config.wall_probe_distance
	if test_move(global_transform, Vector2(-distance, 0), _left_probe):
		accept_normal(_left_probe.get_normal())
	if test_move(global_transform, Vector2(distance, 0), _right_probe):
		accept_normal(_right_probe.get_normal())
	if velocity.y >= 0.0 and test_move(global_transform, Vector2(0, distance), _down_probe):
		accept_normal(_down_probe.get_normal())


func accept_normal(normal: Vector2) -> void:
	if absf(normal.y) <= movement_config.wall_normal_max_y and absf(normal.x) > 0.5:
		contacts.wall_normal = normal
	elif normal.y < -movement_config.wall_normal_max_y:
		if normal.dot(Vector2.UP) >= cos(floor_max_angle) - 0.00001 and velocity.y >= 0.0:
			contacts.grounded = true
		elif normal.dot(Vector2.UP) < cos(floor_max_angle):
			contacts.steep_normal = normal


func clear_selection() -> void:
	if input_layer != null:
		input_layer.clear_dash_selection()


func die(ignore_invulnerability: bool = false) -> bool:
	if motor.machine.current in [PlayerStateMachine.State.DEATH, PlayerStateMachine.State.FINISH]:
		return false
	if motor.invulnerability_ticks > 0 and not ignore_invulnerability:
		return false
	motor.die()
	velocity = Vector2.ZERO
	clear_selection()
	return true


func respawn_at(location: Vector2) -> void:
	global_position = location
	spawn_position = location
	velocity = Vector2.ZERO
	motor.respawn()
	contacts.clear()
	_relocated = true
	clear_selection()
	reset_physics_interpolation()


func finish_run() -> void:
	motor.finish()
	velocity = Vector2.ZERO
	clear_selection()
