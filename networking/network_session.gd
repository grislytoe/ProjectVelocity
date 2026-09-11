class_name NetworkSession
extends Node
## Host-authoritative two-player simulation. Transport is injected and contains no gameplay.

signal status_changed(message: String)
signal event_received(event: Array)

var config := NetworkConfig.new()
var transport: MultiplayerTransport
var course: NetworkCourse
var host: bool = true
var input_layer: InputLayer
var input_provider: Callable
var profile: Array = ["Player", "44cceeff", "ffffffff"]
var guest_profile: Array = ["Guest", "dd88ffff", "ffffffff"]
var session_id: String = ""
var reconnect_token: String = ""
var joined: bool = false
var ended: bool = false
var paused: bool = false
var service_tick: int = 0
var host_tick: int = 0
var client_tick: int = 0
var clock_ticks: int = 0
var last_packet_tick: int = 0
var last_snapshot_tick: int = -1
var last_snapshot_service: int = 0
var reconnect_remaining: int = 0
var rtt_ticks: int = 0
var winner: int = 0
var finish_deadline: int = -1
var round_complete: bool = false
var sequence: int = 65535
var epochs: Array[int] = [0, 0]
var barrier := StartBarrier.new()
var queue := CommandQueue.new()
var prediction := PredictionHistory.new()
var interpolation := SnapshotBuffer.new()
var events := GameplayEvents.new()
var status: String = "Waiting for peer"
var snapshot_count: int = 0
var movement_samples: int = 0
var _dynamics: Array = []
var _hint_ticks: int = 0
var _host_remote_buffer := SnapshotBuffer.new()
var _visual_events: Array = []
var progress: Array[int] = [0, 0]
var packet_counts: Dictionary = {}
var scope_rejections: int = 0
var _paused_blocks: Array[bool] = [true, true]

func _ready() -> void:
	process_physics_priority = 0
	queue.config = config
	prediction.config = config
	interpolation.config = config
	_host_remote_buffer.config = config
	add_child(barrier)
	barrier.arm(course.actors, [&"1", &"2"])
	if host:
		session_id = Crypto.new().generate_random_bytes(16).hex_encode()
		reconnect_token = Crypto.new().generate_random_bytes(16).hex_encode()
		for i: int in 2:
			course.actors[i].died.connect(_death.bind(i))
			course.actors[i].relocated.connect(_respawn.bind(i))
			course.lives[i].checkpoint_activated.connect(_checkpoint.bind(i))
			course.lives[i].completed.connect(_finish.bind(i))
	apply_profiles()

func notify(message: String) -> void:
	status = message
	status_changed.emit(message)

func send(kind: NetPacket.Kind, data: Array = []) -> void:
	transport.send(NetPacket.make(kind, session_id, host_tick, data))

func _physics_process(_delta: float) -> void:
	service_tick += 1
	if ended:
		return
	for packet: NetPacket in transport.poll(service_tick):
		receive(packet)
	if joined and (not transport.connected or service_tick - last_packet_tick > config.timeout_ticks):
		disconnected()
	if service_tick % 30 == 0:
		if not host and not joined and transport.connected:
			transport.send(NetPacket.make(NetPacket.Kind.HELLO, "", 0,
				[course.definition.map_id, course.definition.map_version,
				course.definition.declared_checksum, profile, reconnect_token]))
		elif joined:
			send(NetPacket.Kind.PING, [service_tick])
	if host:
		advance_host()
	else:
		advance_client()

func receive(packet: NetPacket) -> void:
	packet_counts[packet.kind] = int(packet_counts.get(packet.kind, 0)) + 1
	if host and packet.kind == NetPacket.Kind.HELLO:
		var data: Array = packet.data
		if data[0] != course.definition.map_id or int(data[1]) != course.definition.map_version \
			or data[2] != course.definition.declared_checksum:
			notify("Incompatible map ID/version/checksum")
			return
		if (paused or joined) and data[4] != reconnect_token:
			# HELLO retransmission before the first WELCOME needs no token.
			if paused or barrier.gate.start_tick >= 0:
				return
		if not joined and not paused:
			guest_profile = data[3].duplicate()
		joined = true
		last_packet_tick = service_tick
		send(NetPacket.Kind.WELCOME, [reconnect_token, config.snapshot_hz, profile, guest_profile])
		apply_profiles()
		return
	if not host and packet.kind == NetPacket.Kind.WELCOME and not joined:
		if not session_id.is_empty() and packet.session != session_id:
			return
		session_id = packet.session
		reconnect_token = packet.data[0]
		config.snapshot_hz = int(packet.data[1])
		guest_profile = packet.data[2].duplicate()
		joined = true
		host_tick = packet.tick
		client_tick = packet.tick
		last_packet_tick = service_tick
		course.actors[1].start_blocked = true
		apply_profiles()
		notify("Handshake accepted; load/hints then ready")
		return
	if not joined or packet.session != session_id:
		scope_rejections += 1
		return
	# Heartbeat age advances only for directionally valid packets.
	match packet.kind:
		NetPacket.Kind.READY:
			if host:
				last_packet_tick = service_tick
				barrier.gate.set_ready(&"2", true)
				if paused:
					queue.clear()
					var target: Vector2 = course.lives[1].respawn_position
					if not RespawnSafety.valid(course.actors[1], target):
						target = course.lives[1].start_position
					if not RespawnSafety.valid(course.actors[1], target):
						return
					course.actors[1].respawn_at(target, true)
					for i: int in 2:
						course.actors[i].start_blocked = _paused_blocks[i]
					paused = false
					reconnect_remaining = 0
					emit_event(0, GameplayEvents.Kind.RESUME)
					notify("Guest returned; match resumed")
		NetPacket.Kind.INPUT:
			if host and not paused:
				last_packet_tick = service_tick
				var command: InputCommand = InputCommand.decode(packet.data)
				if command.generation == epochs[1]:
					if queue.accept(command, host_tick, service_tick):
						client_tick = command.tick
		NetPacket.Kind.SNAPSHOT:
			if not host:
				accept_snapshot(packet)
		NetPacket.Kind.PING:
			last_packet_tick = service_tick
			send(NetPacket.Kind.PONG, packet.data)
		NetPacket.Kind.PONG:
			if int(packet.data[0]) <= service_tick:
				last_packet_tick = service_tick
				rtt_ticks = service_tick - int(packet.data[0])
		NetPacket.Kind.BYE:
			disconnected()

func sample_input() -> InputFrame:
	if input_provider.is_valid():
		return input_provider.call() as InputFrame
	return input_layer.sample() if input_layer != null else InputFrame.new()

func advance_host() -> void:
	if paused:
		reconnect_remaining -= 1
		if reconnect_remaining <= 0:
			winner = 1
			ended = true
			notify("Reconnect window expired; host wins round")
		return
	host_tick += 1
	if joined:
		_hint_ticks += 1
		if _hint_ticks >= config.hint_ticks:
			barrier.gate.set_ready(&"1", true)
			barrier.gate.schedule(host_tick + config.countdown_ticks, host_tick)
	if barrier.advance(host_tick):
		emit_event(0, GameplayEvents.Kind.START)
		notify("GO")
	if barrier.gate.released and not round_complete:
		clock_ticks += 1
		course.advance_world(true)
		var frames: Array[InputFrame] = [sample_input(), queue.consume()]
		for i: int in 2:
			course.actors[i].advance(frames[i])
			movement_events(i)
		course.advance_world(false)
		if finish_deadline >= 0 and clock_ticks >= finish_deadline:
			for actor: PlayerController in course.actors:
				actor.start_blocked = true
			round_complete = true
			notify("Round complete")
	else:
		queue.consume()
	if joined and service_tick % (60 / config.snapshot_hz) == 0:
		events.prune(host_tick, config.event_lifetime)
		var states: Array = []
		for i: int in 2:
			states.append(ActorState.capture(course.actors[i], epochs[i]).values())
			progress[i] = course.lives[i].progress.reached.size()
		send(NetPacket.Kind.SNAPSHOT, [queue.ack, clock_ticks, barrier.gate.start_tick, paused,
			states, course.capture_dynamics(), events.recent, winner, reconnect_remaining, progress])
		snapshot_count += 1
		last_snapshot_service = service_tick
		_host_remote_buffer.insert(host_tick, ActorState.capture(course.actors[1], epochs[1]))
	var remote_sample: Dictionary = _host_remote_buffer.sample(host_tick - config.interpolation_ticks)
	if not remote_sample.is_empty():
		course.remote.presentation.position = remote_sample.position - course.remote.position
		course.remote.presentation.present(remote_sample.state.visual(
			visual_events_at(host_tick - config.interpolation_ticks)))

func advance_client() -> void:
	if not joined:
		return
	_hint_ticks += 1
	if _hint_ticks >= config.hint_ticks and (barrier.gate.start_tick < 0 or service_tick % 30 == 0):
		send(NetPacket.Kind.READY)
	if paused:
		return
	client_tick += 1
	var age: int = service_tick - last_snapshot_service
	var estimated: int = host_tick + mini(age, config.extrapolation_ticks)
	if not _dynamics.is_empty():
		course.apply_dynamics(_dynamics, mini(age, config.extrapolation_ticks))
	var actor: PlayerController = course.actors[1]
	if not actor.start_blocked:
		var command := InputCommand.new()
		sequence = NetSequence.next(sequence)
		command.sequence = sequence
		command.tick = estimated
		command.generation = maxi(0, prediction.epoch)
		command.frame = sample_input()
		actor.advance(command.frame)
		prediction.record(command, actor)
		send(NetPacket.Kind.INPUT, command.values())
	actor.presentation.position = actor.presentation.position.move_toward(Vector2.ZERO,
		maxf(1, actor.presentation.position.length() / config.smoothing_ticks))
	var rendered: Dictionary = interpolation.sample(estimated - config.interpolation_ticks)
	if not rendered.is_empty():
		course.remote.position = rendered.position
		course.remote.presentation.present(rendered.state.visual(
			visual_events_at(estimated - config.interpolation_ticks)))
		if rendered.state.visual().velocity.length() > 1:
			movement_samples += 1

func accept_snapshot(packet: NetPacket) -> void:
	if packet.tick <= last_snapshot_tick or not course.valid_dynamics(packet.data[5]):
		return
	last_packet_tick = service_tick
	last_snapshot_tick = packet.tick
	last_snapshot_service = service_tick
	host_tick = packet.tick
	clock_ticks = maxi(clock_ticks, int(packet.data[1]))
	barrier.gate.start_tick = int(packet.data[2])
	paused = packet.data[3]
	winner = int(packet.data[7])
	reconnect_remaining = int(packet.data[8])
	progress.assign(packet.data[9])
	for i: int in course.checkpoints.size():
		course.checkpoints[i].local_active = i < progress[1]
		course.checkpoints[i].queue_redraw()
	_dynamics = packet.data[5].duplicate(true)
	course.apply_dynamics(_dynamics)
	var own: ActorState = ActorState.decode(packet.data[4][1])
	prediction.reconcile(own, int(packet.data[0]), course.actors[1])
	interpolation.insert(packet.tick, ActorState.decode(packet.data[4][0]))
	snapshot_count += 1
	for event: Array in events.ingest(packet.data[6], packet.tick, config.event_lifetime):
		event_received.emit(event)
		if int(event[2]) == 1:
			_visual_events.append(event)
		if int(event[3]) == GameplayEvents.Kind.START:
			notify("GO")
		elif int(event[3]) == GameplayEvents.Kind.RESUME:
			notify("Match resumed")
		elif int(event[3]) == GameplayEvents.Kind.FINISH:
			notify("Player %d finished; winner %d" % [int(event[2]), winner])

func movement_events(index: int) -> void:
	var bits: int = course.actors[index].motor.events
	for kind: int in range(5):
		if bits & movement_bit(kind):
			emit_event(index + 1, kind as GameplayEvents.Kind)

static func movement_bit(kind: int) -> int:
	return [1, 2, 4, 8, 32][kind] if kind >= 0 and kind < 5 else 0

func emit_event(player_id: int, kind: GameplayEvents.Kind, detail: int = 0) -> void:
	events.emit_event(host_tick, player_id, kind, detail)
	if player_id == 2:
		_visual_events.append(events.recent.back())
	event_received.emit(events.recent.back())

func visual_events_at(render_tick: int) -> int:
	var bits: int = 0
	for i: int in range(_visual_events.size() - 1, -1, -1):
		var event: Array = _visual_events[i]
		if int(event[1]) <= render_tick:
			if int(event[1]) >= render_tick - 12:
				bits |= movement_bit(int(event[3]))
			_visual_events.remove_at(i)
	while _visual_events.size() > 128:
		_visual_events.pop_front()
	return bits

func remote_buffer_depth() -> int:
	return _host_remote_buffer.samples.size() if host else interpolation.samples.size()

func _death(index: int) -> void:
	epochs[index] += 1
	if index == 1:
		queue.pending.clear()
	emit_event(index + 1, GameplayEvents.Kind.DEATH)
	emit_event(index + 1, GameplayEvents.Kind.HAZARD)

func _respawn(_position: Vector2, index: int) -> void:
	epochs[index] += 1
	if index == 1:
		queue.pending.clear()
	emit_event(index + 1, GameplayEvents.Kind.RESPAWN)

func _checkpoint(_id: StringName, index: int) -> void:
	emit_event(index + 1, GameplayEvents.Kind.CHECKPOINT, course.lives[index].progress.reached.size())

func _finish(index: int) -> void:
	epochs[index] += 1
	emit_event(index + 1, GameplayEvents.Kind.FINISH)
	if winner == 0:
		winner = index + 1
		finish_deadline = clock_ticks + 1800
		notify("Round winner: player %d; 30 seconds remain" % winner)
	elif course.actors[0].motor.machine.current == PlayerStateMachine.State.FINISH \
		and course.actors[1].motor.machine.current == PlayerStateMachine.State.FINISH:
		round_complete = true
		notify("Both players finished")

func disconnected() -> void:
	if not joined:
		return
	joined = false
	prediction.clear()
	interpolation.clear()
	queue.clear()
	_hint_ticks = 0
	if host:
		paused = true
		for i: int in 2:
			_paused_blocks[i] = course.actors[i].start_blocked
			course.actors[i].start_blocked = true
		reconnect_remaining = config.reconnect_ticks
		emit_event(0, GameplayEvents.Kind.DISCONNECT)
		notify("Guest disconnected; match paused for 45 seconds")
	else:
		ended = true
		notify("Host disconnected; match ended. Close or restart Local Network.")

func apply_profiles() -> void:
	for i: int in 2:
		var source: Array = profile if (i == 0) == host else guest_profile
		var value: PlayerProfileData = PlayerProfileData.create()
		value.nickname = source[0]
		value.body_color = source[1]
		value.accent_color = source[2]
		course.actors[i].presentation.apply_profile(value)

func shutdown() -> void:
	if transport != null:
		if joined:
			send(NetPacket.Kind.BYE)
		transport.close()
	joined = false
	ended = true
	queue.clear()
	prediction.clear()
	interpolation.clear()
	_host_remote_buffer.clear()
	events.clear()
	_dynamics.clear()
	_visual_events.clear()
	barrier.actors.clear()

func prepare_reconnect() -> void:
	# Explicit same-process retry retains only the ephemeral bearer token, never a nickname identity.
	if host:
		return
	joined = false
	ended = false
	paused = false
	sequence = 65535
	_hint_ticks = 0
	prediction.clear()
	interpolation.clear()
	_dynamics.clear()
	course.actors[1].start_blocked = true
	notify("Reconnecting to the same local session")

func _exit_tree() -> void:
	shutdown()
