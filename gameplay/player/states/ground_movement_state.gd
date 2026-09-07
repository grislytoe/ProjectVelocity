class_name GroundMovementState
extends PlayerMovementState


func tick(motor: PlayerMotor, frame: InputFrame, _contacts: MovementContacts) -> void:
	motor.horizontal(frame.movement.x, true)
	motor.velocity.y = motor.config.fall_gravity * PlayerMovementConfig.STEP
