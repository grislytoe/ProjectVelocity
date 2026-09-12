extends SceneTree
## Real M13/M14 world and M7/M8/M9 components; packet attacks go through codec/session admission.
var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("M16: " + message)

func snapshot(session: NetworkSession) -> Array:
	return [session.queue.ack, session.clock_ticks, session.barrier.gate.start_tick, session.paused,
		[ActorState.capture(session.course.actors[0]).values(), ActorState.capture(session.course.actors[1]).values()],
		session.course.capture_dynamics(), session.events.recent.duplicate(true), session.winner,
		session.reconnect_remaining, session.progress.duplicate(), RaceBaseline.capture(session)]

func run() -> void:
	for repetition: int in 3:
		var course := NetworkCourse.new()
		course.definition = MapCatalog.industrial()
		root.add_child(course)
		await physics_frame
		await physics_frame
		check(course.diagnostics.valid(), "official track verified")
		var session := NetworkSession.new()
		session.course = course
		session.transport = MultiplayerTransport.new()
		root.add_child(session)
		session.set_physics_process(false)
		session.joined = true
		var before: String = JSON.stringify(snapshot(session))
		for kind: int in range(GameplayEvents.Kind.DEATH, GameplayEvents.Kind.LASER_HIT + 1):
			for tick: int in [0, 1, 999999]:
				var payload: Array = snapshot(session)
				payload[7] = 2
				payload[6] = [[1, tick, 2, kind, 0, 1, 1]]
				var packet := NetPacket.make(NetPacket.Kind.SNAPSHOT, session.session_id, tick, payload)
				session.receive(packet)
				session.receive(packet)
				check(JSON.stringify(snapshot(session)) == before, "critical claim cannot mutate host %d" % kind)
		check(session.scope_rejections >= 100, "directional rejection diagnostics")
		var data: Array = snapshot(session)
		var wire := NetPacket.make(NetPacket.Kind.SNAPSHOT, session.session_id, 1, data)
		check(NetPacket.decode(wire.encode(session.config), session.config) != null, "full baseline wire")
		var old := NetworkConfig.new()
		old.protocol = 2
		check(NetPacket.decode(wire.encode(old), session.config) == null, "protocol 2 rejected")
		for field: int in data[10].size():
			var broken: Array = data.duplicate(true)
			broken[10][field] = {"forged": true}
			check(not NetPacket.valid_snapshot(broken), "strict race field %d" % field)
		data[10][7][1][0] = [127]
		check(not RaceBaseline.matches_map(data[10], course.definition), "map checkpoint registry rejects foreign index")
		var unordered: MapDefinition = course.definition.duplicate() as MapDefinition
		unordered.strict_order = false
		data[10][7][1][0] = [2, 0]
		check(RaceBaseline.valid(data[10]) and RaceBaseline.matches_map(data[10], unordered),
			"non-strict map preserves actual reached set rather than count prefix")
		session.receive(NetPacket.make(NetPacket.Kind.READY, session.session_id, 0, [true, 1]))
		session.barrier.gate.set_ready(&"1", true)
		check(session.barrier.gate.schedule(60, 0), "ready allows countdown")
		session.receive(NetPacket.make(NetPacket.Kind.READY, session.session_id, 0, [false, 2]))
		check(session.barrier.gate.start_tick == -1, "withdrawal cancels countdown")
		session.receive(NetPacket.make(NetPacket.Kind.READY, session.session_id, 0, [true, 1]))
		check(not session.guest_ready, "reordered ready cannot undo withdrawal")
		session.receive(NetPacket.make(NetPacket.Kind.READY, session.session_id, 0, [true, 3]))
		session.barrier.gate.schedule(60, 0)
		check(not session.barrier.advance(59) and session.barrier.advance(60), "exact GO")
		var actor: PlayerController = course.actors[1]
		actor.advance(InputFrame.new())
		check(not course.lives[1].finish() and session.winner == 0, "mandatory Finish guard")
		for point: MapPoint in course.definition.checkpoints:
			check(course.lives[1].checkpoint(point.point_id, course.assembly.point_position(point, true)), "ordered per-player checkpoint")
		check(course.lives[0].progress.reached.is_empty(), "other player independent")
		var safe: Vector2 = course.lives[1].respawn_position
		actor.motor.invulnerability_ticks = 0
		check(actor.die(), "authoritative death")
		for tick: int in 29:
			course.lives[1].advance()
		check(actor.position == safe and actor.motor.invulnerability_ticks > 0, "safe checkpoint respawn and immunity")
		check(not actor.die(), "all fatal hazards observe immunity")
		session.disconnected()
		session.receive(NetPacket.make(NetPacket.Kind.HELLO, "", 0, [course.definition.map_id,
			course.definition.map_version, course.definition.declared_checksum,
			["Guest", "ffffffff", "ffffffff"], session.reconnect_token]))
		session.receive(NetPacket.make(NetPacket.Kind.READY, session.session_id, 0, [true, 4]))
		check(not session.paused and actor.position == safe, "reconnect restores host checkpoint")
		actor.advance(InputFrame.new())
		check(course.lives[1].finish() and session.winner == 2, "first valid Finish wins")
		check(not course.lives[0].finish() and session.winner == 2, "remaining actor cannot self-authorize result")
		course.actors[0].advance(InputFrame.new())
		for point: MapPoint in course.definition.checkpoints:
			course.lives[0].checkpoint(point.point_id, course.assembly.point_position(point, true))
		check(course.lives[0].finish() and session.winner == 2 and session.round_complete,
			"same-tick second valid Finish preserves first accepted winner")
		check(session.finish_times[0] == session.finish_times[1], "simultaneous tick has equal recorded times")
		session.round_complete = true
		session.guest_ready = true
		check(session.retry_round() and session.round_id == 2, "host ready retry transition")
		check(course.lives[1].progress.reached.is_empty() and course.world.active_count() == 0, "round resets progress and pool")
		var viewport := SubViewport.new()
		viewport.world_2d = World2D.new()
		root.add_child(viewport)
		var mirror := NetworkCourse.new()
		mirror.host = false
		mirror.definition = course.definition
		viewport.add_child(mirror)
		var guest := NetworkSession.new()
		guest.host = false
		guest.course = mirror
		guest.transport = MultiplayerTransport.new()
		viewport.add_child(guest)
		guest.set_physics_process(false)
		guest.sequence = 1200
		guest.accept_snapshot(NetPacket.make(NetPacket.Kind.SNAPSHOT, session.session_id, 100, snapshot(session)))
		check(guest.round_id == 2 and guest.sequence == 65535 and guest.prediction.commands.is_empty(),
			"new round baseline rebases guest sequence together with host command queue")
		guest.guest_ready = false
		guest.prepare_reconnect()
		check(guest.guest_ready, "explicit reconnect confirms return after Results withdrew Ready")
		viewport.free()
		for row: Array in course.capture_dynamics():
			if int(row[1]) == 0 or int(row[1]) == 3:
				check(int(row[4]) == 0, "canonical path phase reset")
		var rows: Array = course.capture_dynamics()
		for node: Node2D in course.dynamics:
			if node is MovingPlatform or node is Saw:
				node.position += Vector2(400, 0)
		course.apply_dynamics(rows)
		check(course.capture_dynamics() == rows, "deterministic geometry drift correction")
		for node: Node2D in course.dynamics:
			if node is MovingPlatform:
				actor.start_blocked = false
				actor.respawn_at(node.global_position + Vector2(0, -38), true)
				var previous_epoch: int = session.epochs[1]
				for tick: int in 30:
					await physics_frame
					course.advance_world(true)
					actor.advance(InputFrame.new())
					session.update_support(1)
				check(session.epochs[1] > previous_epoch, "real moving-support contact rebases prediction generation")
				break
		# Actual pooled generations cannot be reused as a new target identity.
		for body: PlayerController in course.actors:
			body.start_blocked = false
			body.advance(InputFrame.new())
		var shot: HazardProjectile = course.world.fire(&"local", Vector2(300, 0),
			Vector2.RIGHT, TurretConfig.new(), 1)
		check(shot != null, "real pool allocates shot")
		if shot != null:
			var generation: int = shot.generation
			shot.recycle()
			var reused: HazardProjectile = course.world.fire(&"absent", Vector2(300, 0),
				Vector2.RIGHT, TurretConfig.new(), 2)
			check(reused == shot and reused.generation == generation + 1, "slot reuse increments stable generation")
			check(is_equal_approx(reused.self_modulate.a, 0.3), "opponent projectile opacity")
			for i: int in 8:
				course.world.fire(&"absent", Vector2(300, 0), Vector2.RIGHT, TurretConfig.new(), 2)
			check(course.world.active_count(&"absent") == 5, "network world enforces per-target five cap")
			for i: int in 8:
				course.world.fire(&"local", Vector2(300, 0), Vector2.RIGHT, TurretConfig.new(), 1)
			check(course.world.active_count() == 10, "network world enforces global ten cap")
			course.reset_world()
			check(course.world.active_count() == 0, "retry retires every target channel")
		session.joined = true
		session.disconnected()
		var stopped_clock: int = session.clock_ticks
		session.reconnect_remaining = 1
		session.advance_host()
		check(session.ended and session.round_complete and session.winner == 1
			and session.clock_ticks == stopped_clock, "expired reconnect awards host without advancing clock")
		session.shutdown()
		check(session.events.recent.is_empty() and session.remote_buffer_depth() == 0, "bounded histories teardown")
		session.free()
		course.free()
		await process_frame
	if failures == 0:
		print("PROJECTVELOCITY_M16_RACE_OK")
	quit(0 if failures == 0 else 1)
