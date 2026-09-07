class_name AirMovementState
extends PlayerMovementState


func tick(motor: PlayerMotor, frame: InputFrame, contacts: MovementContacts) -> void:
	motor.horizontal(frame.movement.x, false)
	if not contacts.steep_normal.is_zero_approx() and motor.velocity.y >= 0.0:
		# A steep support surface slides under gravity; it is not a wall-slide surface.
		var gravity := Vector2.DOWN * motor.config.fall_gravity * motor.config.slope_gravity_multiplier
		motor.velocity += gravity.slide(contacts.steep_normal) * PlayerMovementConfig.STEP
		motor.velocity = motor.velocity.slide(contacts.steep_normal)
		motor.velocity = motor.velocity.limit_length(motor.config.terminal_velocity)
	else:
		motor.gravity(frame.jump_held)
