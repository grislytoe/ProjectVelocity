class_name PlayerAnimationMachine
extends RefCounted
## Presentation state only. Never mutates movement or ability availability.

enum Pose {
	IDLE, RUN, JUMP, FALL, DOUBLE_JUMP, WALL_SLIDE, WALL_JUMP, DASH,
	LANDING, DEATH, RESPAWN, FINISH_VICTORY, TURNAROUND, SKID, FAST_FALL_RESERVED,
}

var current: Pose = Pose.IDLE
var playback_speed: float = 1.0
var phase: float = 0.0
var _remaining: int = 0
var _braking: bool = false


func advance(motor: PlayerMotor) -> void:
	playback_speed = maxf(0.15, absf(motor.velocity.x) / motor.config.ground_max_speed)
	phase += playback_speed * PlayerMovementConfig.STEP * 12.0
	_remaining = maxi(0, _remaining - 1)
	var state: PlayerStateMachine.State = motor.machine.current
	var reversing: bool = motor.requested_horizontal * motor.velocity.x < 0.0 and absf(motor.velocity.x) > 100.0
	if state == PlayerStateMachine.State.DEATH:
		current = Pose.DEATH
	elif state == PlayerStateMachine.State.RESPAWN:
		current = Pose.RESPAWN
	elif state == PlayerStateMachine.State.FINISH:
		current = Pose.FINISH_VICTORY
	elif state == PlayerStateMachine.State.DASH:
		current = Pose.DASH
	elif motor.events & PlayerMotor.Event.DOUBLE_JUMPED:
		current = Pose.DOUBLE_JUMP
		_remaining = 11
	elif motor.events & PlayerMotor.Event.WALL_JUMPED:
		current = Pose.WALL_JUMP
		_remaining = 8
	elif motor.events & PlayerMotor.Event.LANDED:
		current = Pose.LANDING
		_remaining = 6
	elif state == PlayerStateMachine.State.WALL_SLIDE:
		current = Pose.WALL_SLIDE
	elif state in [PlayerStateMachine.State.JUMP, PlayerStateMachine.State.FALL]:
		if _remaining == 0 or current not in [Pose.DOUBLE_JUMP, Pose.WALL_JUMP]:
			current = Pose.JUMP if motor.velocity.y < 0.0 else Pose.FALL
	elif _remaining == 0:
		if current == Pose.SKID:
			current = Pose.TURNAROUND
			_remaining = 4
		elif reversing and not _braking:
			current = Pose.SKID
			_remaining = 5
		else:
			current = Pose.RUN if state == PlayerStateMachine.State.RUN else Pose.IDLE
	_braking = reversing
