class_name PlayerAnimationMachine
extends RefCounted
## Cosmetic transitions consume detached values and never gate gameplay.

enum Pose {
	IDLE, RUN, JUMP, FALL, DOUBLE_JUMP, WALL_SLIDE, WALL_JUMP, DASH,
	LANDING, DEATH, RESPAWN, FINISH_VICTORY, TURNAROUND, SKID, FAST_FALL_RESERVED,
}
const STATE_POSES: Dictionary = {
	PlayerStateMachine.State.IDLE: Pose.IDLE, PlayerStateMachine.State.RUN: Pose.RUN,
	PlayerStateMachine.State.JUMP: Pose.JUMP, PlayerStateMachine.State.FALL: Pose.FALL,
	PlayerStateMachine.State.WALL_SLIDE: Pose.WALL_SLIDE,
	PlayerStateMachine.State.WALL_JUMP: Pose.WALL_JUMP, PlayerStateMachine.State.DASH: Pose.DASH,
	PlayerStateMachine.State.DEATH: Pose.DEATH, PlayerStateMachine.State.RESPAWN: Pose.RESPAWN,
	PlayerStateMachine.State.FINISH: Pose.FINISH_VICTORY,
}
var current: Pose = Pose.IDLE
var playback_speed: float = 1.0
var phase: float = 0.0
var age_ticks: int = 0
var _remaining: int = 0
var _braking: bool = false


func enter(pose: Pose, duration: int = 0) -> void:
	if current != pose:
		current = pose
		age_ticks = 0
		_remaining = duration


func advance(frame: PlayerVisualFrame) -> void:
	playback_speed = clampf(frame.speed_ratio, 0.15, 2.0)
	phase += playback_speed * 0.2
	age_ticks += 1
	_remaining = maxi(0, _remaining - 1)
	var state: PlayerStateMachine.State = frame.state
	var reversing: bool = frame.requested_horizontal * frame.velocity.x < 0 and absf(frame.velocity.x) > 100
	if state in [PlayerStateMachine.State.DEATH, PlayerStateMachine.State.FINISH, PlayerStateMachine.State.DASH]:
		enter(STATE_POSES[state])
	elif state == PlayerStateMachine.State.RESPAWN:
		enter(Pose.RESPAWN, 15)
	elif frame.events & PlayerMotor.Event.DOUBLE_JUMPED:
		enter(Pose.DOUBLE_JUMP, 11)
	elif frame.events & PlayerMotor.Event.WALL_JUMPED:
		enter(Pose.WALL_JUMP, 8)
	elif frame.events & PlayerMotor.Event.JUMPED:
		enter(Pose.JUMP)
	elif frame.events & PlayerMotor.Event.LANDED:
		enter(Pose.LANDING, 6)
	elif state == PlayerStateMachine.State.WALL_SLIDE:
		enter(Pose.WALL_SLIDE)
	elif state == PlayerStateMachine.State.WALL_JUMP:
		enter(Pose.WALL_JUMP)
	elif current == Pose.RESPAWN and _remaining > 0:
		pass
	elif state in [PlayerStateMachine.State.JUMP, PlayerStateMachine.State.FALL]:
		if _remaining == 0 or current not in [Pose.DOUBLE_JUMP, Pose.WALL_JUMP]:
			enter(STATE_POSES[state])
	elif _remaining == 0 or current not in [Pose.SKID, Pose.TURNAROUND, Pose.LANDING]:
		if current == Pose.SKID:
			enter(Pose.TURNAROUND, 4)
		elif reversing and not _braking:
			enter(Pose.SKID, 5)
		else:
			enter(STATE_POSES.get(state, Pose.IDLE))
	_braking = reversing
