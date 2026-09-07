class_name PlayerVisualFrame
extends RefCounted
## Value snapshot. No reference to a controller, motor, input service or network peer.

var state: PlayerStateMachine.State = PlayerStateMachine.State.IDLE
var events: int = 0
var velocity: Vector2 = Vector2.ZERO
var speed_ratio: float = 0.0
var requested_horizontal: float = 0.0
var wall_side: float = 0.0
var dash_vector: Vector2 = Vector2.RIGHT
var jump_ready: bool = true
var dash_ready: bool = true
var invulnerable: bool = false


static func from_motor(motor: PlayerMotor) -> PlayerVisualFrame:
	var value := PlayerVisualFrame.new()
	value.state = motor.machine.current
	value.events = motor.events
	value.velocity = motor.velocity
	value.speed_ratio = absf(motor.velocity.x) / motor.config.ground_max_speed
	value.requested_horizontal = motor.requested_horizontal
	value.wall_side = motor.wall_side
	value.dash_vector = motor.dash_vector
	value.jump_ready = motor.double_jump_available
	value.dash_ready = motor.dash_available
	value.invulnerable = motor.invulnerability_ticks > 0
	return value
