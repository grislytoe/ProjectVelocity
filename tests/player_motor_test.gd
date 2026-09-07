extends SceneTree

var checks: int = 0
var failures: int = 0
var config := PlayerMovementConfig.new()
var air := MovementContacts.new()
var floor_contact := MovementContacts.new()
var wall := MovementContacts.new()


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func frame(x: float = 0.0, jump: bool = false, held: bool = false, dash: Vector2 = Vector2.ZERO) -> InputFrame:
	var value := InputFrame.new()
	value.movement.x = x
	value.jump_pressed = jump
	value.jump_held = held
	value.dash_pressed = not dash.is_zero_approx()
	value.dash_direction = dash
	return value


func run() -> void:
	floor_contact.grounded = true
	wall.wall_normal = Vector2.LEFT
	check(config.validate(), "default config valid")
	var invalid: PlayerMovementConfig = config.duplicate() as PlayerMovementConfig
	invalid.ground_acceleration = NAN
	check(not invalid.validate(), "reject nonfinite tuning")
	invalid = config.duplicate() as PlayerMovementConfig
	invalid.dash_duration = 0
	check(not invalid.validate(), "reject zero dash duration")
	check(PlayerMovementConfig.ticks(0.1) == 6, "coyote quantization")
	check(PlayerMovementConfig.ticks(0.15) == 9, "dash quantization")
	var motor := PlayerMotor.new(config)
	motor.step(frame(), floor_contact)
	check(motor.machine.current == PlayerStateMachine.State.IDLE, "idle")
	motor.step(frame(1), floor_contact)
	check(is_equal_approx(motor.velocity.x, 80), "ground acceleration uses fixed step")
	for tick: int in 30:
		motor.step(frame(1), floor_contact)
	check(is_equal_approx(motor.velocity.x, config.ground_max_speed), "ground max speed")
	check(motor.machine.current == PlayerStateMachine.State.RUN, "run")
	for tick: int in 20:
		motor.step(frame(), floor_contact)
	check(is_zero_approx(motor.velocity.x), "ground deceleration")
	motor = PlayerMotor.new(config)
	motor.step(frame(1), air)
	check(is_equal_approx(motor.velocity.x, config.air_acceleration / 60), "air acceleration")
	for tick: int in 120:
		motor.step(frame(1), air)
	check(is_equal_approx(motor.velocity.x, config.air_max_speed), "air max speed")
	check(is_equal_approx(motor.velocity.y, config.terminal_velocity), "terminal velocity")
	for tick: int in 60:
		motor.step(frame(), air)
	check(is_zero_approx(motor.velocity.x), "air deceleration")
	check(jump_height(true) > jump_height(false) * 1.5, "variable jump changes apex")
	for delay: int in range(1, 8):
		motor = PlayerMotor.new(config)
		motor.step(frame(), floor_contact)
		for tick: int in delay - 1:
			motor.step(frame(), air)
		motor.step(frame(0, true, true), air)
		check(motor.double_jump_available == (delay <= 6), "coyote window tick %d" % delay)
	motor = PlayerMotor.new(config)
	motor.step(frame(0, true, true), floor_contact)
	check(motor.events & PlayerMotor.Event.JUMPED != 0, "ground jump event")
	motor.step(frame(0, true, true), air)
	check(not motor.double_jump_available, "extra jump consumed")
	check(motor.events & PlayerMotor.Event.DOUBLE_JUMPED != 0, "distinct double jump event")
	var before: float = motor.velocity.y
	motor.step(frame(0, true, true), air)
	check(motor.velocity.y > before, "third jump rejected")
	motor.velocity.y = 50
	motor.step(frame(0, true, false), air)
	motor.step(frame(), floor_contact)
	check(motor.velocity.y >= 0, "no jump buffer on landing")
	check(motor.double_jump_available and motor.dash_available, "landing refresh")
	motor = PlayerMotor.new(config)
	motor.velocity.y = 800
	motor.double_jump_available = false
	motor.dash_available = false
	motor.step(frame(), wall)
	check(motor.machine.current == PlayerStateMachine.State.WALL_SLIDE, "wall slide state")
	check(motor.velocity.y > 0 and motor.velocity.y <= config.wall_slide_speed, "wall slide never hangs")
	check(motor.double_jump_available and motor.dash_available, "wall refresh")
	motor.step(frame(1, true, true), wall)
	check(motor.machine.current == PlayerStateMachine.State.WALL_JUMP, "wall jump state")
	check(motor.velocity.x == -config.wall_jump_horizontal_force and motor.velocity.y < 0, "wall jump outward/upward")
	for tick: int in 8:
		motor.step(frame(1, false, true), air)
		check(motor.velocity.x == -config.wall_jump_horizontal_force, "wall input lock %d" % tick)
	motor.step(frame(1, false, true), air)
	check(motor.velocity.x > -config.wall_jump_horizontal_force, "wall lock expires")
	test_dash()
	test_lifecycle()
	var slope := MovementContacts.new()
	slope.steep_normal = Vector2(-0.8660254, -0.5)
	motor = PlayerMotor.new(config)
	motor.step(frame(), slope)
	check(motor.velocity.x < 0 and motor.velocity.y > 0, "steep slope slides downhill")
	test_presentation()
	if failures == 0:
		print("PROJECTVELOCITY_M3_MOTOR_OK (%d checks)" % checks)
	quit(0 if failures == 0 else 1)


func jump_height(held: bool) -> float:
	var motor := PlayerMotor.new(config)
	motor.step(frame(0, true, held), floor_contact)
	var height: float = 0
	while motor.velocity.y < 0:
		height -= motor.velocity.y / 60
		motor.step(frame(0, false, held), air)
	return height


func test_dash() -> void:
	for index: int in 8:
		var direction: Vector2 = Vector2.RIGHT.rotated(index * PI / 4)
		var motor := PlayerMotor.new(config)
		motor.velocity = Vector2(100, 900)
		motor.step(frame(0, false, false, direction), air)
		check(motor.machine.current == PlayerStateMachine.State.DASH, "dash state")
		check(not motor.dash_available, "dash consumes ability")
		for tick: int in 9:
			check(motor.velocity.distance_to(direction * config.dash_speed) < 0.001, "dash fixed speed/direction %d:%d" % [index, tick])
			motor.step(frame(-1, true, false, -direction), air)
		check(motor.machine.current != PlayerStateMachine.State.DASH, "dash exact nine ticks")
		check(absf(motor.velocity.x - direction.x * config.dash_speed * config.dash_momentum_retention) < 0.001, "dash retention")
		check(motor.end_lag_ticks > 0, "dash end lag")
		var x: float = motor.velocity.x
		motor.step(frame(-1, false, false, direction), air)
		check(is_equal_approx(motor.velocity.x, x), "end lag locks steering")
		check(motor.machine.current != PlayerStateMachine.State.DASH, "unavailable dash rejected")
	var motor := PlayerMotor.new(config)
	motor.dash_available = false
	var selected: InputFrame = frame(0, false, false, Vector2.RIGHT)
	motor.step(selected, air)
	selected.dash_pressed = false
	motor.step(selected, floor_contact)
	check(motor.machine.current != PlayerStateMachine.State.DASH and motor.dash_available, "selection never auto fires on refresh")
	var cancel_config: PlayerMovementConfig = config.duplicate() as PlayerMovementConfig
	cancel_config.dash_cancel_enabled = true
	motor = PlayerMotor.new(cancel_config)
	motor.step(frame(0, false, false, Vector2.RIGHT), air)
	motor.step(frame(0, true, true), air)
	check(motor.machine.current == PlayerStateMachine.State.JUMP, "opt-in dash cancellation")
	check(not motor.double_jump_available, "cancel consumes extra jump")
	motor = PlayerMotor.new(cancel_config)
	motor.step(frame(0, true, true, Vector2.RIGHT), air)
	check(motor.machine.current == PlayerStateMachine.State.DASH, "dash wins simultaneous activation even with cancellation enabled")


func test_lifecycle() -> void:
	var motor := PlayerMotor.new(config)
	motor.start_dash(Vector2.DOWN)
	motor.die()
	motor.step(frame(1, true, true, Vector2.RIGHT), floor_contact)
	check(motor.machine.current == PlayerStateMachine.State.DEATH and motor.velocity == Vector2.ZERO, "death locks movement")
	check(motor.dash_vector == Vector2.ZERO and motor.dash_ticks == 0, "death clears transient state")
	motor.respawn()
	check(motor.machine.current == PlayerStateMachine.State.RESPAWN, "respawn state")
	check(motor.double_jump_available and motor.dash_available and motor.invulnerability_ticks == 45, "respawn ability/invulnerability reset")
	motor.step(frame(), air)
	check(motor.machine.current == PlayerStateMachine.State.FALL, "respawn exits")
	for tick: int in 44:
		motor.step(frame(), air)
	check(motor.invulnerability_ticks == 0, "invulnerability fixed duration")
	motor.finish()
	motor.step(frame(1, true, true, Vector2.RIGHT), air)
	check(motor.machine.current == PlayerStateMachine.State.FINISH and motor.velocity == Vector2.ZERO, "finish locks movement")


func test_presentation() -> void:
	var motor := PlayerMotor.new(config)
	var animation := PlayerAnimationMachine.new()
	motor.machine.transition(PlayerStateMachine.State.RUN)
	motor.velocity.x = 600
	motor.requested_horizontal = -1
	animation.advance(PlayerVisualFrame.from_motor(motor))
	check(animation.current == PlayerAnimationMachine.Pose.SKID, "reversal skid")
	for tick: int in 5:
		animation.advance(PlayerVisualFrame.from_motor(motor))
	check(animation.current == PlayerAnimationMachine.Pose.TURNAROUND, "skid to turnaround")
	for tick: int in 4:
		animation.advance(PlayerVisualFrame.from_motor(motor))
	check(animation.current == PlayerAnimationMachine.Pose.RUN, "turnaround to run")
	motor.events = PlayerMotor.Event.DOUBLE_JUMPED
	animation.advance(PlayerVisualFrame.from_motor(motor))
	check(animation.current == PlayerAnimationMachine.Pose.DOUBLE_JUMP, "double jump distinct pose")
	check(motor.velocity.x == 600, "presentation cannot steer motor")
