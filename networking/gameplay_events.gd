class_name GameplayEvents
extends RefCounted

enum Kind { JUMP, DOUBLE_JUMP, WALL_JUMP, DASH, LAND, DEATH, RESPAWN, CHECKPOINT,
	FINISH, START, HAZARD, DISCONNECT, RESUME, SKIPPED_CHECKPOINT, PLATFORM_BREAK,
	PLATFORM_RESTORE, JUMP_PAD, HAZARD_PHASE, TURRET_FIRE, PROJECTILE_HIT, POOL_RETURN,
	ROUND_TRANSITION, WINNER, SAW_HIT, LASER_HIT }
var sequence: int = 0
var recent: Array = []
var seen: Dictionary = {}
var received: int = 0
var duplicates: int = 0
var round_id: int = 1

func emit_event(tick: int, player: int, kind: Kind, detail: int = 0, generation: int = 0) -> void:
	sequence += 1
	recent.append([sequence, tick, player, kind, detail, round_id, generation])
	while recent.size() > 128:
		recent.pop_front()

func prune(tick: int, lifetime: int) -> void:
	while not recent.is_empty() and recent[0][1] < tick - lifetime:
		recent.pop_front()
	for id: Variant in seen.keys():
		if seen[id] < tick - lifetime:
			seen.erase(id)

func ingest(events: Array, tick: int, lifetime: int) -> Array:
	var result: Array = []
	for event: Array in events:
		if seen.has(int(event[0])):
			duplicates += 1
			continue
		if event[1] < tick - lifetime or event[1] > tick:
			continue
		seen[int(event[0])] = int(event[1])
		while seen.size() > 512:
			seen.erase(seen.keys()[0])
		received += 1
		result.append(event.duplicate())
	result.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	prune(tick, lifetime)
	return result

func clear() -> void:
	recent.clear()
	seen.clear()
