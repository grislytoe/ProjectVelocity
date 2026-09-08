class_name PlayerLifecycle
extends Node
## Explicitly bound per-player owner; never reads saves or stops race time.

signal notification(key: String)
signal checkpoint_activated(id: StringName)
signal completed

const DEATH_TICKS: int = 27
var player: PlayerController
var progress := CheckpointProgress.new()
var start_position: Vector2
var respawn_position: Vector2
var death_ticks: int = 0
var blocked_reported: bool = false


func bind(actor: PlayerController, start: Vector2) -> void:
	player = actor
	start_position = start
	respawn_position = start
	process_physics_priority = 50
	player.died.connect(_on_death)


func _on_death() -> void:
	death_ticks = DEATH_TICKS
	blocked_reported = false


func _physics_process(_delta: float) -> void:
	advance()


func advance() -> void:
	if not is_instance_valid(player) or player.motor.machine.current != PlayerStateMachine.State.DEATH:
		death_ticks = 0
		return
	if death_ticks > 0:
		death_ticks -= 1
		return
	var target: Vector2 = respawn_position
	if not RespawnSafety.valid(player, target):
		target = start_position
	if RespawnSafety.valid(player, target):
		player.respawn_at(target)
	elif not blocked_reported:
		blocked_reported = true
		notification.emit("M7_UNSAFE_RESPAWN")
	# Fail closed and retry while dead if even Start is obstructed.


func checkpoint(id: StringName, position: Vector2) -> bool:
	if player.start_blocked or player.motor.machine.locked() or not progress.can_activate(id):
		return false
	if not RespawnSafety.valid(player, position):
		notification.emit("M7_UNSAFE_RESPAWN")
		return false
	progress.activate(id)
	respawn_position = position
	checkpoint_activated.emit(id)
	notification.emit("M7_CHECKPOINT")
	return true


func finish() -> bool:
	if player.start_blocked or player.motor.machine.locked():
		return false
	if not progress.can_finish():
		notification.emit("M7_SKIPPED_CHECKPOINT")
		return false
	player.finish_run()
	completed.emit()
	notification.emit("M7_FINISH")
	return true
