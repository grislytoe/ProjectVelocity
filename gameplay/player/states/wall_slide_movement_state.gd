class_name WallSlideMovementState
extends PlayerMovementState


func tick(motor: PlayerMotor, frame: InputFrame, _contacts: MovementContacts) -> void:
	motor.horizontal(frame.movement.x, false)
	var acceleration: float = motor.config.fall_gravity * motor.config.wall_slide_gravity_multiplier
	motor.velocity.y = minf(
		motor.velocity.y + acceleration * PlayerMovementConfig.STEP, motor.config.wall_slide_speed)
