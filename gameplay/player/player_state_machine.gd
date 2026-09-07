class_name PlayerStateMachine
extends RefCounted

signal state_changed(previous: State, current: State)

enum State { IDLE, RUN, JUMP, FALL, WALL_SLIDE, WALL_JUMP, DASH, DEATH, RESPAWN, FINISH }

var current: State = State.FALL
var _states: Dictionary = {}


func _init() -> void:
	var ground := GroundMovementState.new()
	var air := AirMovementState.new()
	var locked := LockedMovementState.new()
	_states = {
		State.IDLE: ground, State.RUN: ground, State.JUMP: air, State.FALL: air,
		State.WALL_SLIDE: WallSlideMovementState.new(), State.WALL_JUMP: WallJumpMovementState.new(),
		State.DASH: DashMovementState.new(), State.DEATH: locked,
		State.RESPAWN: locked, State.FINISH: locked,
	}


func transition(next: State) -> void:
	if current == next:
		return
	var previous: State = current
	current = next
	state_changed.emit(previous, current)


func locked() -> bool:
	return current in [State.DEATH, State.RESPAWN, State.FINISH]


func tick(motor: PlayerMotor, frame: InputFrame, contacts: MovementContacts) -> void:
	var state: PlayerMovementState = _states[current]
	state.tick(motor, frame, contacts)


func label() -> String:
	return State.keys()[current]
