class_name WallJumpMovementState
extends PlayerMovementState


func tick(motor: PlayerMotor, frame: InputFrame, _contacts: MovementContacts) -> void:
	# Horizontal control remains locked while wall_lock_ticks > 0.
	motor.horizontal(frame.movement.x, false)
	motor.gravity(frame.jump_held)
