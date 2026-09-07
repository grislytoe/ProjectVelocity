class_name PlayerMotor
extends RefCounted
## Fixed-tick movement simulation: no SceneTree, rendering, Input polling or network calls.

enum Event {
	JUMPED = 1, DOUBLE_JUMPED = 2, WALL_JUMPED = 4, DASH_STARTED = 8,
	DASH_ENDED = 16, LANDED = 32,
}

var config: PlayerMovementConfig
var machine := PlayerStateMachine.new()
var velocity: Vector2 = Vector2.ZERO
var double_jump_available: bool = true
var dash_available: bool = true
var dash_vector: Vector2 = Vector2.ZERO
var coyote_ticks: int = 0
var wall_lock_ticks: int = 0
var dash_ticks: int = 0
var end_lag_ticks: int = 0
var invulnerability_ticks: int = 0
var tick_count: int = 0
var events: int = 0
var requested_horizontal: float = 0.0
var wall_side: float = 0.0
var _was_grounded: bool = false


func _init(movement_config: PlayerMovementConfig) -> void:
	config = movement_config


func step(frame: InputFrame, contacts: MovementContacts) -> void:
	events = 0
	requested_horizontal = frame.movement.x
	wall_side = contacts.wall_normal.x
	tick_count += 1
	if machine.locked():
		machine.tick(self, frame, contacts)
		decay_timers()
		return
	if contacts.grounded:
		coyote_ticks = PlayerMovementConfig.ticks(config.coyote_time) + 1
	if contacts.grounded or contacts.has_wall() or not contacts.steep_normal.is_zero_approx():
		double_jump_available = true
		dash_available = true
	classify(contacts)
	if machine.current != PlayerStateMachine.State.DASH and end_lag_ticks == 0:
		if frame.dash_pressed and dash_available and frame.dash_direction.is_finite() and (
			not frame.dash_direction.is_zero_approx()):
			start_dash(frame.dash_direction)
		elif frame.jump_pressed and can_jump(contacts):
			jump(contacts)
	machine.tick(self, frame, contacts)
	decay_timers()


func classify(contacts: MovementContacts) -> void:
	if machine.locked() or machine.current == PlayerStateMachine.State.DASH:
		return
	if contacts.grounded and velocity.y >= 0.0:
		if not _was_grounded:
			events |= Event.LANDED
		machine.transition(PlayerStateMachine.State.RUN if absf(velocity.x) > 0.1 else PlayerStateMachine.State.IDLE)
	elif wall_lock_ticks > 0:
		machine.transition(PlayerStateMachine.State.WALL_JUMP)
	elif contacts.has_wall() and velocity.y >= 0.0:
		machine.transition(PlayerStateMachine.State.WALL_SLIDE)
	else:
		machine.transition(PlayerStateMachine.State.JUMP if velocity.y < 0.0 else PlayerStateMachine.State.FALL)
	_was_grounded = contacts.grounded


func horizontal(direction: float, grounded: bool) -> void:
	if wall_lock_ticks > 0 or end_lag_ticks > 0:
		return
	direction = clampf(direction, -1.0, 1.0)
	var speed: float = config.ground_max_speed if grounded else config.air_max_speed
	var acceleration: float = config.ground_acceleration if grounded else config.air_acceleration
	var deceleration: float = config.ground_deceleration if grounded else config.air_deceleration
	velocity.x = move_toward(velocity.x, direction * speed,
		(acceleration if absf(direction) > 0.001 else deceleration) * PlayerMovementConfig.STEP)


func gravity(jump_held: bool) -> void:
	var amount: float = config.rise_gravity if velocity.y < 0.0 else config.fall_gravity
	if velocity.y < 0.0 and not jump_held:
		amount *= config.jump_cut_gravity_multiplier
	velocity.y = minf(velocity.y + amount * PlayerMovementConfig.STEP, config.terminal_velocity)


func can_jump(contacts: MovementContacts) -> bool:
	return contacts.grounded or coyote_ticks > 0 or contacts.has_wall() or (
		not contacts.steep_normal.is_zero_approx()) or double_jump_available


func jump(contacts: MovementContacts) -> void:
	if contacts.has_wall() and not contacts.grounded:
		velocity = Vector2(contacts.wall_normal.x * config.wall_jump_horizontal_force,
			-config.wall_jump_vertical_force)
		wall_lock_ticks = PlayerMovementConfig.ticks(config.wall_jump_input_lock_time)
		double_jump_available = true
		dash_available = true
		events |= Event.WALL_JUMPED
		machine.transition(PlayerStateMachine.State.WALL_JUMP)
	else:
		var ground_jump: bool = contacts.grounded or coyote_ticks > 0 or (
			not contacts.steep_normal.is_zero_approx())
		velocity.y = -config.jump_force if ground_jump else -config.second_jump_force
		if not ground_jump:
			double_jump_available = false
			events |= Event.DOUBLE_JUMPED
		else:
			events |= Event.JUMPED
		machine.transition(PlayerStateMachine.State.JUMP)
	coyote_ticks = 0


func start_dash(direction: Vector2) -> void:
	dash_vector = InputLayer.quantize_dash(direction)
	velocity = dash_vector * config.dash_speed
	dash_ticks = PlayerMovementConfig.ticks(config.dash_duration)
	dash_available = false
	coyote_ticks = 0
	wall_lock_ticks = 0
	events |= Event.DASH_STARTED
	machine.transition(PlayerStateMachine.State.DASH)


func end_dash(apply_lag: bool) -> void:
	velocity = dash_vector * config.dash_speed * config.dash_momentum_retention
	end_lag_ticks = PlayerMovementConfig.ticks(config.dash_end_lag) if apply_lag else 0
	dash_ticks = 0
	events |= Event.DASH_ENDED
	machine.transition(PlayerStateMachine.State.FALL)


func decay_timers() -> void:
	coyote_ticks = maxi(0, coyote_ticks - 1)
	wall_lock_ticks = maxi(0, wall_lock_ticks - 1)
	end_lag_ticks = maxi(0, end_lag_ticks - 1)
	invulnerability_ticks = maxi(0, invulnerability_ticks - 1)


func die() -> void:
	velocity = Vector2.ZERO
	clear_temporary()
	machine.transition(PlayerStateMachine.State.DEATH)


func respawn() -> void:
	velocity = Vector2.ZERO
	clear_temporary()
	double_jump_available = true
	dash_available = true
	invulnerability_ticks = PlayerMovementConfig.ticks(config.respawn_invulnerability)
	machine.transition(PlayerStateMachine.State.RESPAWN)


func finish() -> void:
	velocity = Vector2.ZERO
	clear_temporary()
	machine.transition(PlayerStateMachine.State.FINISH)


func clear_temporary() -> void:
	coyote_ticks = 0
	wall_lock_ticks = 0
	dash_ticks = 0
	end_lag_ticks = 0
	dash_vector = Vector2.ZERO
	_was_grounded = false
	events = 0
