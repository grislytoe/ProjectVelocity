class_name DashMovementState
extends PlayerMovementState


func tick(motor: PlayerMotor, frame: InputFrame, contacts: MovementContacts) -> void:
	if motor.config.dash_cancel_enabled and frame.jump_pressed and motor.can_jump(contacts) and (
		motor.events & PlayerMotor.Event.DASH_STARTED == 0):
		motor.end_dash(false)
		motor.jump(contacts)
		motor.machine.tick(motor, frame, contacts)
		return
	if motor.dash_ticks == 0:
		motor.end_dash(true)
		motor.gravity(frame.jump_held)
		return
	motor.velocity = motor.dash_vector * motor.config.dash_speed
	motor.dash_ticks -= 1
