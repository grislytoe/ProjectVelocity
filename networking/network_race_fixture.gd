class_name NetworkRaceFixture
extends RefCounted
## Developer-only host relocations into the loaded map's real collision components.
var claims_sent: int = 0
var fixture_steps: Dictionary = {}
var retry_requested: bool = false
var ready_round: int = 0
var series_mode: bool = false

func retry(session: NetworkSession) -> void:
	if session.series.phase != OnlineSeries.Phase.BETWEEN_ROUND_READY \
		or ready_round == session.series.round_generation:
		return
	ready_round = session.series.round_generation
	if session.host:
		retry_requested = session.retry_round()
	else:
		session.set_local_ready(true)
		retry_requested = true

func step(session: NetworkSession) -> void:
	if series_mode:
		step_series(session)
		return
	var course: NetworkCourse = session.course
	var tick: int = session.clock_ticks
	if not session.host or session.round_id > 1:
		return
	var actor: PlayerController = course.actors[1]
	var target := Vector2.ZERO
	var label: String = ""
	if tick >= 1200 and (tick - 1200) % 30 == 0:
		var index: int = (tick - 1200) / 30
		var host_actor: PlayerController = course.actors[0]
		if index < course.checkpoints.size():
			host_actor.respawn_at(course.checkpoints[index].global_position, true)
		elif index == course.checkpoints.size() and session.finish_times[0] < 0:
			host_actor.respawn_at(course.finish.global_position, true)
	if tick == 80:
		target = course.finish.global_position
		label = "invalid_finish"
	elif tick == 140:
		for node: Node2D in course.dynamics:
			if node is Saw:
				target = node.global_position
				label = "saw"
				break
	elif tick == 220:
		for node: Node2D in course.dynamics:
			if node is CycleHazard and not node.spike_visual and node.permanent:
				target = node.global_position
				label = "laser"
				break
	elif tick == 300:
		for node: Node2D in course.dynamics:
			if node is BreakablePlatform:
				target = node.global_position + Vector2(0, -38)
				label = "breakable"
				break
	elif tick == 440:
		var pads: Array[Node] = course.find_children("*", "JumpPad", true, false)
		if not pads.is_empty():
			target = (pads[0] as Node2D).global_position + Vector2(0, -38)
			label = "jump_pad"
	elif tick == 520:
		for node: Node2D in course.dynamics:
			if node is Turret:
				target = node.global_position + Vector2(240, 0)
				label = "turret"
				break
	elif tick >= 800 and (tick - 800) % 45 == 0:
		var index: int = (tick - 800) / 45
		if index < course.checkpoints.size():
			target = course.checkpoints[index].global_position
			label = "checkpoint_%d" % index
		elif index == course.checkpoints.size():
			target = course.finish.global_position
			label = "valid_finish"
	if not label.is_empty() and not fixture_steps.has(label):
		actor.respawn_at(target, true)
		actor.motor.invulnerability_ticks = 0
		fixture_steps[label] = tick

func step_series(session: NetworkSession) -> void:
	if not session.host or session.series.phase not in [OnlineSeries.Phase.RACING,
			OnlineSeries.Phase.FINISH_WINDOW]:
		return
	var tick: int = session.clock_ticks - session._round_started_clock
	var guest_first: bool = session.series.round_index % 2 == 1
	var first_index: int = 1 if guest_first else 0
	var second_index: int = 0 if guest_first else 1
	_series_move(session, first_index, tick, 50)
	# Round two deliberately leaves the remaining player unfinished so the real
	# two-process acceptance observes the full authoritative 1800-tick DNF window.
	if session.series.round_index != 2:
		_series_move(session, second_index, tick, 220)

func _series_move(session: NetworkSession, actor_index: int, tick: int, base: int) -> void:
	if session.series.current_finish_times[actor_index] >= 0:
		return
	var course: NetworkCourse = session.course
	var key: String = "%d:%d:%d" % [session.series.round_generation, actor_index, tick]
	for checkpoint_index: int in course.checkpoints.size():
		if tick == base + checkpoint_index * 18 and not fixture_steps.has(key):
			course.actors[actor_index].respawn_at(course.checkpoints[checkpoint_index].global_position, true)
			fixture_steps[key] = tick
			return
	if tick == base + course.checkpoints.size() * 18 + 18 and not fixture_steps.has(key):
		course.actors[actor_index].respawn_at(course.finish.global_position, true)
		fixture_steps[key] = tick

func attack(session: NetworkSession) -> void:
	if session.host or not session.joined or session.clock_ticks < 30 \
		or session.service_tick % 15 != 0:
		return
	# Each class is an actual transport packet. A client has no critical-event command kind.
	var states: Array = []
	for actor: PlayerController in session.course.actors:
		states.append(ActorState.capture(actor).values())
	var base: Array = [0, session.clock_ticks, 0, false, states,
		session.course.capture_dynamics(), [], 0, 0, [0, 0], RaceBaseline.capture(session)]
	for kind: int in [GameplayEvents.Kind.CHECKPOINT, GameplayEvents.Kind.DEATH,
		GameplayEvents.Kind.RESPAWN, GameplayEvents.Kind.FINISH, GameplayEvents.Kind.WINNER,
		GameplayEvents.Kind.PLATFORM_BREAK, GameplayEvents.Kind.JUMP_PAD,
		GameplayEvents.Kind.HAZARD_PHASE, GameplayEvents.Kind.SAW_HIT,
		GameplayEvents.Kind.LASER_HIT, GameplayEvents.Kind.TURRET_FIRE,
		GameplayEvents.Kind.PROJECTILE_HIT, GameplayEvents.Kind.POOL_RETURN,
		GameplayEvents.Kind.ROUND_TRANSITION]:
		var forged: Array = base.duplicate(true)
		forged[6] = [[1, session.host_tick, 2, kind, 0, session.round_id, 1]]
		forged[7] = 2
		session.send(NetPacket.Kind.SNAPSHOT, forged)
		claims_sent += 1
