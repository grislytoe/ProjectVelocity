class_name ReadyStart
extends RefCounted
## Transport-free authoritative tick gate. Loading and hints precede scheduling.

var participants: Dictionary = {}
var start_tick: int = -1
var released: bool = false


func configure(ids: Array[StringName]) -> bool:
	var next: Dictionary = {}
	for id: StringName in ids:
		if id == &"" or next.has(id):
			return false
		next[id] = false
	if next.is_empty():
		return false
	participants = next
	start_tick = -1
	released = false
	return true


func set_ready(id: StringName, ready: bool) -> bool:
	if not participants.has(id) or released:
		return false
	participants[id] = ready
	if not ready:
		start_tick = -1
	return true


func schedule(authoritative_tick: int, now_tick: int) -> bool:
	if released or start_tick >= 0 or participants.is_empty() or authoritative_tick <= now_tick:
		return false
	for ready: bool in participants.values():
		if not ready:
			return false
	start_tick = authoritative_tick
	return true


func advance(authoritative_tick: int) -> bool:
	if released or start_tick < 0 or authoritative_tick < start_tick:
		return false
	released = true
	return true
