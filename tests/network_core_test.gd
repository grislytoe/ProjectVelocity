extends SceneTree
## Pure adversarial protocol tests plus real CharacterBody2D / map / lifecycle integration.

var failures: int = 0
var config := NetworkConfig.new()
var scope: String = "a".repeat(32)

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("M15: " + message)

func command(sequence: int, tick: int) -> InputCommand:
	var value := InputCommand.new()
	value.sequence = sequence
	value.tick = tick
	value.frame.movement = Vector2.RIGHT
	return value

func run() -> void:
	check(config.valid(), "valid configured 60/20 rates")
	config.snapshot_hz = 30
	check(config.valid(), "30 Hz snapshots supported")
	config.snapshot_hz = 20
	check(NetSequence.newer(0, 65535) and not NetSequence.newer(65535, 0), "sequence wrap")
	check(not NetSequence.newer(22, 22) and not NetSequence.newer(32768, 0), "duplicate and ambiguous half range")
	codec_tests()
	fragment_tests()
	queue_tests()
	buffer_tests()
	event_tests()
	emulator_tests()
	await collision_tests()
	if failures == 0:
		print("PROJECTVELOCITY_M15_CORE_OK")
	quit(0 if failures == 0 else 1)

func codec_tests() -> void:
	var packet := NetPacket.make(NetPacket.Kind.INPUT, scope, 100, command(0, 100).values())
	check(NetPacket.decode(packet.encode(config), config) != null, "input packet roundtrip")
	var incompatible := NetworkConfig.new()
	incompatible.protocol += 1
	check(NetPacket.decode(packet.encode(incompatible), config) == null, "protocol mismatch before mutation")
	for bytes: PackedByteArray in [PackedByteArray(), "{}".to_utf8_buffer(), "[".to_utf8_buffer(),
		"[2,99,0,0,[]]".to_utf8_buffer(), "[".repeat(20).to_utf8_buffer(),
		"x".repeat(config.max_packet_bytes + 1).to_utf8_buffer()]:
		check(NetPacket.decode(bytes, config) == null, "malformed/unknown/oversize rejected")
	var base: Array = command(0, 100).values()
	for index: int in base.size():
		var broken: Array = base.duplicate()
		broken[index] = {"position": [9999, 1]}
		check(InputCommand.decode(broken) == null, "strict input field type %d" % index)
	for bad: float in [NAN, INF, 1.1]:
		var broken: Array = base.duplicate()
		broken[2] = bad
		check(InputCommand.decode(broken) == null, "finite bounded axes")
	base.append([10000, 10000])
	check(InputCommand.decode(base) == null, "no transform claims or extra fields")
	var hello := NetPacket.make(NetPacket.Kind.HELLO, "", 0,
		["map", 1, "a".repeat(64), ["Guest", "ffffffff", "ffffffff"], ""])
	check(NetPacket.decode(hello.encode(config), config) != null, "anonymous session handshake, no persistent identity")
	hello.data[3][0] = "Invalid\nName"
	check(NetPacket.decode(hello.encode(config), config) == null, "nickname control character rejected")

func queue_tests() -> void:
	var queue := CommandQueue.new()
	check(queue.accept(command(0, 100), 100, 100), "first input")
	check(not queue.accept(command(0, 100), 100, 100), "duplicate")
	check(not queue.accept(command(65535, 100), 100, 100), "old sequence")
	check(not queue.accept(command(1, 131), 100, 100), "future input")
	check(not queue.accept(command(1, 0), 200, 100), "stale input")
	check(queue.accept(command(2, 100), 100, 100), "loss skips sequence safely")
	check(not queue.accept(command(1, 100), 100, 100), "out of order input")
	check(queue.ack == 65535, "ack only after simulation consumption")
	queue.consume()
	check(queue.ack == 0, "ack simulated sequence")
	queue.consume()
	check(queue.ack == 2 and queue.consume().movement == Vector2.ZERO, "safe missing-input neutral")
	queue.clear()
	for i: int in 100:
		queue.accept(command(i, 100), 100, 100)
		queue.consume()
	check(queue.rejected >= 10, "rate cap")
	queue.clear()
	for i: int in 30:
		queue.accept(command(i, 100), 100, 200)
	check(queue.pending.size() == config.command_queue_limit, "bounded queue")
	queue.clear()
	check(queue.pending.is_empty() and queue.ack == 65535, "queue teardown")

func fragment_tests() -> void:
	var sender := PacketFragments.new()
	var receiver := PacketFragments.new()
	var data: PackedByteArray = "abcde".repeat(10000).to_utf8_buffer()
	var parts: Array[PackedByteArray] = sender.split(data)
	check(parts.size() == 50 and parts[0].size() <= 1016, "MTU-safe datagrams")
	check(receiver.join(parts[0], 0).is_empty(), "partial message cannot reach decoder")
	check(receiver.join(parts[0], 0).is_empty(), "duplicate fragment cannot complete early")
	var result := PackedByteArray()
	for i: int in range(parts.size() - 1, 0, -1):
		var complete: PackedByteArray = receiver.join(parts[i], 1)
		if not complete.is_empty(): result = complete
	check(result == data, "out-of-order fragments reconstruct exactly")
	check(receiver.join(parts[0], 2).is_empty(), "completed fragment replay ignored")
	parts = sender.split(data)
	receiver.join(parts[0], 3)
	receiver.prune(64)
	check(receiver.pending.is_empty(), "lost fragment expiration")
	var invalid: PackedByteArray = parts[0].duplicate()
	invalid.encode_u32(12, 9999999)
	check(receiver.join(invalid, 65).is_empty() and receiver.rejected > 0, "oversize reassembly rejected")
	receiver.clear()
	check(receiver.completed.is_empty(), "fragment teardown")

func state_at(x: float, epoch: int = 0) -> ActorState:
	var value := ActorState.new()
	value.position = Vector2(x, 0)
	value.epoch = epoch
	value.blocked = false
	value.motor_values = [[60, 0], true, true, [1, 0], 0, 0, 0, 0, 0, 0, 0, 1, 0, false, 0, 0]
	return value

func buffer_tests() -> void:
	var buffer := SnapshotBuffer.new()
	buffer.insert(20, state_at(20))
	buffer.insert(10, state_at(10))
	buffer.insert(20, state_at(999))
	check(buffer.samples.size() == 2 and buffer.sample(15).position.x == 15, "ordered interpolation/dedup")
	check(buffer.sample(1000).position.x == 23, "bounded extrapolation then hold")
	buffer.insert(30, state_at(500, 1))
	buffer.insert(25, state_at(25, 0))
	check(buffer.samples.size() == 1 and buffer.sample(20).position.x == 500, "relocation clears old epoch")
	for i: int in 100:
		buffer.insert(40 + i, state_at(i, 1))
	check(buffer.samples.size() == config.buffer_limit, "bounded jitter buffer")
	buffer.clear()
	check(buffer.sample(0).is_empty(), "buffer teardown")

func event_tests() -> void:
	var events := GameplayEvents.new()
	var batch: Array = [[2, 10, 1, 3, 0], [1, 9, 2, 5, 0]]
	var accepted: Array = events.ingest(batch, 10, 120)
	check(accepted.size() == 2 and accepted[0][0] == 1, "events sorted by stable ID")
	check(events.ingest(batch, 10, 120).is_empty(), "event deduplication")
	check(events.ingest([[3, 500, 1, 1, 0], [4, 0, 1, 1, 0]], 200, 120).is_empty(), "future and expired events")
	for i: int in 1000:
		events.emit_event(i, 1, GameplayEvents.Kind.JUMP)
	check(events.recent.size() == 128, "bounded event retransmission")
	events.clear()
	check(events.seen.is_empty() and events.recent.is_empty(), "event teardown")

func emulator_tests() -> void:
	var first := NetworkEmulator.new()
	var second := NetworkEmulator.new()
	first.configure("stress", 1500)
	second.configure("stress", 1500)
	var trace_a: Array = []
	var trace_b: Array = []
	for tick: int in 300:
		var packet := NetPacket.make(NetPacket.Kind.PING, scope, tick, [tick])
		first.enqueue(packet, tick)
		second.enqueue(packet, tick)
		for item: NetPacket in first.poll(tick): trace_a.append([tick, item.tick])
		for item: NetPacket in second.poll(tick): trace_b.append([tick, item.tick])
	check(trace_a == trace_b and first.dropped > 0, "seeded latency/jitter/loss/duplicate/reorder")
	first.close()
	check(first.pending.is_empty(), "emulator shutdown releases packets")

func collision_tests() -> void:
	for repeat: int in 2:
		var course := NetworkCourse.new()
		if repeat == 1:
			course.definition = MapCatalog.industrial()
		root.add_child(course)
		await physics_frame
		await physics_frame
		check(course.diagnostics.valid() and course.validate_respawns(), "validated real map collision")
		var session := NetworkSession.new()
		session.transport = MultiplayerTransport.new()
		session.course = course
		root.add_child(session)
		session.set_physics_process(false)
		var original_scope: String = session.session_id
		session.receive(NetPacket.make(NetPacket.Kind.HELLO, "", 0,
			["wrong_map", 1, "a".repeat(64), ["Guest", "ffffffff", "ffffffff"], ""]))
		check(not session.joined and session.session_id == original_scope, "incompatible map handshake rejected")
		check(course.actors[0].position == course.actors[1].position, "both players share Start")
		check(is_equal_approx(course.actors[1].presentation.modulate.a, 0.3), "remote opacity")
		check(not course.actors[1].presentation.is_local, "remote ownership")
		session.barrier.gate.set_ready(&"1", true)
		check(not session.barrier.gate.schedule(60, 0), "not ready cannot start")
		session.barrier.gate.set_ready(&"2", true)
		check(session.barrier.gate.schedule(60, 0), "host authorizes synchronized GO")
		check(not session.barrier.advance(59) and session.barrier.advance(60), "exact host GO tick")
		var actor: PlayerController = course.actors[1]
		var history := PredictionHistory.new()
		history.epoch = 0
		var initial: ActorState = ActorState.capture(actor)
		for i: int in 12:
			await physics_frame
			actor.advance(command(i, i).frame)
			history.record(command(i, i), actor)
		check(actor.position.x > initial.position.x + 10, "real body movement")
		check(course.actors[0].position == initial.position, "independent actor input")
		var expected: Vector2 = actor.position
		var authority: ActorState = history.states[5]
		actor.position += Vector2(180, -40)
		history.reconcile(authority, 5, actor)
		check(actor.position.distance_to(expected) < 1, "rewind/replay uses same collision motor")
		check(history.last_error > 96 and history.hard_snaps == 1, "injected divergence forces hard correction")
		check(history.commands.size() == 6, "ack prunes history only through processed input")
		var decoded: ActorState = ActorState.decode(ActorState.capture(actor).values())
		check(decoded != null, "full rollback state codec")
		decoded.epoch = 1
		decoded.position = initial.position
		history.reconcile(decoded, 11, actor)
		check(history.commands.is_empty() and history.hard_snaps > 0, "relocation clears prediction/camera interpolation")
		for i: int in config.history_limit + 1:
			history.record(command(i, i), actor)
		check(history.commands.size() == config.history_limit and history.overflowed, "bounded prediction history")
		history.reconcile(decoded, 0, actor)
		check(history.commands.is_empty(), "history overflow safely rebases")
		actor.gameplay_authority = false
		check(not actor.die(), "guest cannot confirm death")
		actor.gameplay_authority = true
		actor.motor.invulnerability_ticks = 0
		check(actor.die(), "host death primitive")
		for i: int in 30: course.lives[1].advance()
		check(actor.motor.machine.current == PlayerStateMachine.State.RESPAWN, "host respawn primitive")
		actor.advance(InputFrame.new())
		check(not course.lives[1].finish(), "Finish rejected before mandatory checkpoints")
		for point: MapPoint in course.definition.checkpoints:
			check(course.lives[1].checkpoint(point.point_id,
				course.assembly.point_position(point, true)), "host validated checkpoint")
		check(course.lives[1].finish() and session.winner == 2, "host Finish/winner")
		var kinds: Array = []
		for event: Array in session.events.recent: kinds.append(event[3])
		for kind: int in [5, 6, 7, 8, 10]: check(kind in kinds, "replicated lifecycle event %d" % kind)
		check(course.valid_dynamics(course.capture_dynamics()), "dynamic snapshot registry")
		var rows: Array = course.capture_dynamics()
		var payload: Array = [0, 0, -1, false, [ActorState.capture(course.actors[0]).values(),
			ActorState.capture(course.actors[1]).values()], rows, [], 0, 0, [0, 0]]
		var packet := NetPacket.make(NetPacket.Kind.SNAPSHOT, scope, 100, payload)
		check(NetPacket.decode(packet.encode(config), config) != null, "complete snapshot wire roundtrip")
		var viewport := SubViewport.new()
		viewport.world_2d = World2D.new()
		root.add_child(viewport)
		var mirror := NetworkCourse.new()
		mirror.host = false
		mirror.definition = course.definition
		viewport.add_child(mirror)
		check(mirror.valid_dynamics(rows), "same registry on independent client world")
		mirror.apply_dynamics(rows, 2)
		check(not mirror.actors[1].gameplay_authority and mirror.actors[0].collision_mask == 0,
			"client prediction owns one actor, remote cannot collide")
		viewport.free()
		session.joined = true
		session.disconnected()
		var frozen_tick: int = session.host_tick
		session.advance_host()
		check(session.paused and session.host_tick == frozen_tick and session.reconnect_remaining == 2699,
			"disconnect pauses host simulation with 45s budget")
		session.shutdown()
		check(session.events.recent.is_empty() and session.prediction.commands.is_empty(), "session teardown")
		session.free()
		course.free()
		await process_frame
	print("M15_SCENE_REPEAT_COUNT=2")
