class_name LockedMovementState
extends PlayerMovementState


func tick(motor: PlayerMotor, _frame: InputFrame, _contacts: MovementContacts) -> void:
	motor.velocity = Vector2.ZERO
	if motor.machine.current == PlayerStateMachine.State.RESPAWN:
		# One neutral physics tick after relocation; no held edge is replayed.
		motor.machine.transition(PlayerStateMachine.State.FALL)
