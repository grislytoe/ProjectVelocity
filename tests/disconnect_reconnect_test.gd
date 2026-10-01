extends SceneTree
## M22 deterministic disconnect/reconnect authority, timing, phase and cleanup coverage.

var failures: int = 0

class RecordingTransport extends MultiplayerTransport:
	var sent: Array[NetPacket] = []

	func send(packet: NetPacket) -> void:
		sent.append(packet)

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("M22: " + message)

func configure_running(series: OnlineSeries, definition: MapDefinition) -> void:
	series.configure(definition, 2)
	series.loaded = [true, true]
	series.begin_hint(0, 0)
	series.begin_countdown(1, 0)
	series.begin_race(1)

func reconnect_hello(session: NetworkSession, bearer: String, identity: String,
		generation: int, series_generation: int = -1, round_generation: int = -1) -> NetPacket:
	return NetPacket.make(NetPacket.Kind.HELLO, "", 0, [session.course.definition.map_id,
		session.course.definition.map_version, session.course.definition.declared_checksum,
		["Guest", "ffffffff", "ffffffff"], bearer, BuildInfo.NETWORK_WIRE_REVISION,
		BuildInfo.BUILD_NUMBER, identity,
		session.series.series_generation if series_generation < 0 else series_generation,
		session.series.round_generation if round_generation < 0 else round_generation, generation])

func run() -> void:
	var definition: MapDefinition = MapCatalog.training()
	var exact := OnlineSeries.new()
	configure_running(exact, definition)
	check(exact.enter_reconnect(100, 2700), "active round enters reconnect exactly once")
	check(not exact.enter_reconnect(100, 2700), "duplicate disconnect is idempotent")
	check(exact.reconnect_deadline_service_tick == 2800 and exact.reconnect_remaining(100) == 2700,
		"production window is an absolute 2700 service ticks")
	check(exact.begin_reconnect_handshake(2800, 1, 1, 1),
		"authoritative deadline tick is the last admissible reconnect tick")
	check(exact.baseline_sent(1) and exact.baseline_accepted(2800, 1, 1, 1)
		and exact.resume_reconnect() and exact.phase == OnlineSeries.Phase.RACING,
		"baseline acknowledgement gates resume")

	var expired := OnlineSeries.new()
	configure_running(expired, definition)
	expired.enter_reconnect(100, 2700)
	check(not expired.reconnect_expired(2800) and expired.reconnect_expired(2801),
		"first tick after the inclusive deadline expires")
	check(not expired.begin_reconnect_handshake(2801, 1, 1, 1),
		"post-expiry reconnect is rejected")
	check(expired.award_guest_disconnect([3, 2], [[0, 1, 2], [0, 1]])
		and not expired.award_guest_disconnect([3, 2], [[], []]) and expired.score == [1, 0],
		"expiry awards host exactly once")

	var phases: Array[int] = [OnlineSeries.Phase.SYNCHRONIZED_LOADING,
		OnlineSeries.Phase.CONTROLS_HINT, OnlineSeries.Phase.COUNTDOWN, OnlineSeries.Phase.RACING,
		OnlineSeries.Phase.FINISH_WINDOW, OnlineSeries.Phase.ROUND_RESULTS,
		OnlineSeries.Phase.BETWEEN_ROUND_READY, OnlineSeries.Phase.FINAL_SERIES_RESULTS]
	for phase: int in phases:
		var item := OnlineSeries.new()
		item.configure(definition, 2)
		item.phase = phase as OnlineSeries.Phase
		check(item.enter_reconnect(10, 2700), "phase %s pauses" % OnlineSeries.Phase.keys()[phase])
		var mutable: bool = phase in [OnlineSeries.Phase.SYNCHRONIZED_LOADING,
			OnlineSeries.Phase.CONTROLS_HINT, OnlineSeries.Phase.COUNTDOWN,
			OnlineSeries.Phase.RACING, OnlineSeries.Phase.FINISH_WINDOW]
		check(item.reconnect_round_mutable() == mutable, "phase %s mutable policy" % phase)
		check(not item.resume_reconnect(), "phase %s cannot self-resume" % phase)
		check(item.begin_reconnect_handshake(11, 1, 1, 1) and item.baseline_sent(1)
			and item.baseline_accepted(11, 1, 1, 1) and item.resume_reconnect()
			and item.phase == phase, "phase %s restores exactly" % phase)

	var immutable := OnlineSeries.new()
	configure_running(immutable, definition)
	immutable.record_finish(1, 10, 7, [0, 1, 2, 3, 4, 5, 6], 10)
	immutable.current_finish_times[1] = 11
	immutable.finalize_round(OnlineSeries.ResultReason.NORMAL)
	var immutable_score: Array[int] = immutable.score.duplicate()
	immutable.enter_reconnect(20, 2700)
	immutable.reconnect_expired(2721)
	check(not immutable.award_guest_disconnect([7, 7], [[], []])
		and immutable.score == immutable_score and immutable.round_results.size() == 1,
		"immutable result cannot resume gameplay or double-award")

	var course := NetworkCourse.new()
	course.definition = definition
	root.add_child(course)
	await physics_frame
	await physics_frame
	var session := NetworkSession.new()
	session.course = course
	session.transport = MultiplayerTransport.new()
	root.add_child(session)
	session.set_physics_process(false)
	session.joined = true
	session.series.loaded = [true, true]
	session.series.begin_hint(0, 0)
	session.series.begin_countdown(1, 0)
	session.series.begin_race(1)
	session.barrier.gate.start_tick = 1
	session.barrier.gate.released = true
	session.advance_host()
	var frozen_host_tick: int = session.host_tick
	var frozen_clock: int = session.clock_ticks
	var frozen_dynamics: String = JSON.stringify(course.capture_dynamics())
	var frozen_positions: Array[Vector2] = [course.actors[0].position, course.actors[1].position]
	var identity: String = "d".repeat(32)
	session._guest_reconnect_identity = identity
	session.disconnected()
	for tick: int in 120:
		session.service_tick += 1
		session.advance_host()
	check(session.host_tick == frozen_host_tick and session.clock_ticks == frozen_clock
		and JSON.stringify(course.capture_dynamics()) == frozen_dynamics
		and course.actors[0].position == frozen_positions[0]
		and course.actors[1].position == frozen_positions[1],
		"service clock alone advances while players/world/race clock are frozen")

	var state_before_attack: String = JSON.stringify(session.series.capture())
	session.receive(reconnect_hello(session, "", identity, session.series.reconnect_generation))
	session.receive(reconnect_hello(session, "f".repeat(32), identity,
		session.series.reconnect_generation))
	session.receive(reconnect_hello(session, session.reconnect_token, "c".repeat(32),
		session.series.reconnect_generation))
	session.receive(reconnect_hello(session, session.reconnect_token, identity,
		session.series.reconnect_generation, session.series.series_generation + 1))
	session.receive(reconnect_hello(session, session.reconnect_token, identity,
		session.series.reconnect_generation - 1))
	check(JSON.stringify(session.series.capture()) == state_before_attack and not session.joined,
		"empty/wrong bearer, foreign identity and stale generations do not mutate authority")

	# A valid reconnect carries checkpoint progress but falls back to Start if the saved point is unsafe.
	course.lives[1].progress.reached.append(course.lives[1].progress.ordered_ids[0])
	course.lives[1].respawn_position = Vector2(999999, 999999)
	session.service_tick = session.series.reconnect_deadline_service_tick
	session.receive(reconnect_hello(session, session.reconnect_token, identity,
		session.series.reconnect_generation))
	check(session.joined and session.series.reconnect_state == OnlineSeries.ReconnectState.BASELINE_SENT
		and course.actors[1].position == course.lives[1].start_position
		and course.lives[1].progress.reached.size() == 1
		and course.actors[1].motor.invulnerability_ticks > 0,
		"authenticated baseline uses collision-safe Start fallback and preserves progress/immunity")
	var recording := RecordingTransport.new()
	session.transport = recording
	session.host = false
	session.last_snapshot_tick = session._reconnect_baseline_tick
	var states: Array = []
	for actor: PlayerController in course.actors:
		states.append(ActorState.capture(actor).values())
	var repeated_baseline := NetPacket.make(NetPacket.Kind.SNAPSHOT, session.session_id,
		session._reconnect_baseline_tick, [session.queue.ack, session.clock_ticks,
		session.barrier.gate.start_tick, true, states, course.capture_dynamics(), [],
		session.winner, session.reconnect_remaining, session.progress, RaceBaseline.capture(session)])
	session.accept_snapshot(repeated_baseline)
	session.accept_snapshot(repeated_baseline)
	check(recording.sent.size() == 2
		and recording.sent[0].kind == NetPacket.Kind.RECONNECT_READY
		and recording.sent[0].data == recording.sent[1].data,
		"repeated frozen baseline retries an identical generation-bound acknowledgement")
	session.host = true
	var old_token: String = session.reconnect_token
	session.receive(NetPacket.make(NetPacket.Kind.RECONNECT_READY, session.session_id, 0,
		[session.series.series_generation, session.series.round_generation,
		session.series.reconnect_generation, session._reconnect_baseline_tick]))
	check(not session.paused and session.reconnect_token != old_token
		and session.queue.pending.is_empty() and session.prediction.commands.is_empty()
		and session.interpolation.samples.is_empty(),
		"atomic resume rotates bearer and clears stale command/prediction/interpolation queues")
	var resumed_state: String = JSON.stringify(session.series.capture())
	session.receive(reconnect_hello(session, old_token, identity, session.series.reconnect_generation))
	check(JSON.stringify(session.series.capture()) == resumed_state,
		"replayed consumed bearer cannot reopen or mutate resumed game")

	for cycle: int in 3:
		session.joined = true
		session.disconnected()
		session.receive(reconnect_hello(session, session.reconnect_token, identity,
			session.series.reconnect_generation))
		session.receive(NetPacket.make(NetPacket.Kind.RECONNECT_READY, session.session_id, 0,
			[session.series.series_generation, session.series.round_generation,
			session.series.reconnect_generation, session._reconnect_baseline_tick]))
		check(not session.paused and session.queue.pending.is_empty()
			and session.events.recent.size() <= 1, "bounded repeated reconnect cycle %d" % cycle)

	session.shutdown()
	check(session.prediction.commands.is_empty() and session.interpolation.samples.is_empty()
		and session.events.recent.is_empty() and course.world.active_count() == 0,
		"teardown leaves zero gameplay/network queues")
	session.free(); course.free()
	await process_frame
	if failures == 0:
		print("PROJECTVELOCITY_M22_RECONNECT_OK")
	quit(0 if failures == 0 else 1)
