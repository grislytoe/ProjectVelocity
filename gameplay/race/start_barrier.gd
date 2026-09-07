class_name StartBarrier
extends Node
## Freeze registered actors until a single authoritative GO tick; no transport or race timer.

signal started(tick: int)
var gate := ReadyStart.new()
var actors: Array[PlayerController] = []


func arm(players: Array[PlayerController], ids: Array[StringName]) -> bool:
	if players.size() != ids.size() or not actors.is_empty() or not gate.configure(ids):
		return false
	actors = players.duplicate()
	for player: PlayerController in actors:
		player.start_blocked = true
		player.velocity = Vector2.ZERO
		player.motor.velocity = Vector2.ZERO
		player.clear_selection()
	return true


func advance(tick: int) -> bool:
	if not gate.advance(tick):
		return false
	for player: PlayerController in actors:
		if is_instance_valid(player):
			player.clear_selection()
			player.start_blocked = false
	started.emit(gate.start_tick)
	actors.clear()
	return true
