class_name RaceBaseline
extends RefCounted
## Durable state complements transient effects. Checkpoint indices belong to the verified map.

enum Phase { LOADING, COUNTDOWN, RUNNING, FINISHING, RESULTS, RECONNECT, ENDED }

static func capture(session: NetworkSession) -> Array:
	var lives: Array = []
	for i: int in 2:
		var life: PlayerLifecycle = session.course.lives[i]
		var reached: Array = []
		for id: StringName in life.progress.reached:
			reached.append(life.progress.ordered_ids.find(id))
		lives.append([reached, life.respawn_position.x, life.respawn_position.y,
			life.death_ticks, session.deaths[i], session.finish_times[i]])
	return [session.round_id, session.phase(), session.finish_deadline,
		session.round_complete, maxi(0, session._accepted_ready_revision), session.guest_ready,
		session.events.sequence, lives]

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() != 8:
		return false
	if not NetPacket.integer(value[0], 1, 2147483647) \
		or not NetPacket.integer(value[1], 0, Phase.ENDED) \
		or not NetPacket.integer(value[2], -1, 2147483647) or not value[3] is bool \
		or not NetPacket.integer(value[4], 0, 2147483647) or not value[5] is bool \
		or not NetPacket.integer(value[6], 0, 2147483647) \
		or not value[7] is Array or value[7].size() != 2:
		return false
	for life: Variant in value[7]:
		if not life is Array or life.size() != 6 or not life[0] is Array or life[0].size() > 128 \
			or not NetPacket.number(life[1], 1000000) or not NetPacket.number(life[2], 1000000) \
			or not NetPacket.integer(life[3], 0, PlayerLifecycle.DEATH_TICKS) \
			or not NetPacket.integer(life[4], 0, 2147483647) \
			or not NetPacket.integer(life[5], -1, 2147483647):
			return false
		var seen: Array = []
		for index: Variant in life[0]:
			if not NetPacket.integer(index, 0, 127) or index in seen:
				return false
			seen.append(index)
	return true

static func matches_map(value: Array, definition: MapDefinition) -> bool:
	for life: Array in value[7]:
		for i: int in life[0].size():
			if int(life[0][i]) >= definition.checkpoint_ids.size() \
				or (definition.strict_order and int(life[0][i]) != i):
				return false
	return true

static func apply(value: Array, session: NetworkSession) -> void:
	session.round_id = int(value[0])
	session.remote_phase = int(value[1])
	session.finish_deadline = int(value[2])
	session.round_complete = value[3]
	for i: int in 2:
		var row: Array = value[7][i]
		var life: PlayerLifecycle = session.course.lives[i]
		life.progress.reached.clear()
		for index: Variant in row[0]:
			life.progress.reached.append(life.progress.ordered_ids[int(index)])
		life.respawn_position = Vector2(row[1], row[2])
		life.death_ticks = int(row[3])
		session.deaths[i] = int(row[4])
		session.finish_times[i] = int(row[5])
