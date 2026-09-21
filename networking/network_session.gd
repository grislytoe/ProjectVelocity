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
var last_pong_service: int = -1000
var measured_rtt_ms: float = 0
var _ping_times: Dictionary = {}
var telemetry := NetworkTelemetry.new()
var winner: int = 0
var finish_deadline: int = -1
var round_complete: bool = false
var series := OnlineSeries.new()
var configured_rounds: int = 1
var loaded_revision: int = 0
var action_revision: int = 0
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
var round_id: int = 1
var remote_phase: int = OnlineSeries.Phase.SERIES_PREPARATION
var deaths: Array[int] = [0, 0]
var finish_times: Array[int] = [-1, -1]
var ready_revision: int = 0
var guest_ready: bool = true
var _accepted_ready_revision: int = -1
var _previous_phase: int = -1
var _intent_window: int = 0
var _intent_count: int = 0
var _round_started_clock: int = 0
var _support_ids: Array[int] = [-1, -1]
var last_simulated_sequence: int = 65535
var _results_enter_tick: int = -1
var _reported_invalid_snapshot: bool = false

func update_support(index: int) -> void:
	var actor: PlayerController = course.actors[index]
	var support: int = -1
	for i: int in actor.get_slide_collision_count():
		var collision: KinematicCollision2D = actor.get_slide_collision(i)
		if collision.get_collider() is MovingPlatform and collision.get_normal().dot(Vector2.UP) > 0.7:
			support = course.dynamics.find(collision.get_collider())
	if support != _support_ids[index]:
		_support_ids[index] = support
		epochs[index] += 1
		if index == 1:
			queue.pending.clear()

func phase() -> int:
	if ended: return OnlineSeries.Phase.ENDED
	return series.phase if host else remote_phase

func set_local_ready(value: bool) -> void:
	ready_revision += 1
	var player: int = 1 if host else 2
	if host:
		series.set_ready(player, value, series.series_generation, series.round_generation, ready_revision)
		guest_ready = series.ready[1]
	else:
		guest_ready = value
		if joined:
			send(NetPacket.Kind.READY, [value, ready_revision,
				series.series_generation, series.round_generation])

func retry_round() -> bool:
	if not host or not joined or paused or series.phase != OnlineSeries.Phase.BETWEEN_ROUND_READY:
		return false
	set_local_ready(true)
	if not series.both_ready():
		return true
	return _begin_next_round()

func _begin_next_round() -> bool:
	if not series.begin_next_round():
		return false
	queue.clear()
	prediction.clear()
	interpolation.clear()
	_host_remote_buffer.clear()
	_visual_events.clear()
	events.recent.clear()
	round_id = series.round_generation
	course.reset_world()
	barrier.arm(course.actors, [&"1", &"2"])
	winner = 0
	finish_deadline = -1
	round_complete = false
	deaths = [0, 0]
	finish_times = [-1, -1]
	progress = [0, 0]
	_support_ids = [-1, -1]
	last_simulated_sequence = 65535
	_hint_ticks = 0
	for i: int in 2: epochs[i] += 1
	loaded_revision += 1
	series.confirm_loaded(1, series.series_generation, series.round_generation,
		series.map_id, series.map_version, series.map_checksum, loaded_revision)
	return true

func request_series_action(action: OnlineSeries.Action) -> bool:
	action_revision += 1
	if not host:
		if joined:
			send(NetPacket.Kind.SERIES_ACTION, [action, action_revision,
				series.series_generation, series.round_generation])
		return false
	match action:
		OnlineSeries.Action.PLAY_AGAIN:
			if not series.play_again(): return false
			_reset_for_new_series()
			return true
		OnlineSeries.Action.RETURN_TO_LOBBY:
			if not series.return_to_lobby(): return false
			course.reset_world()
			return true
		OnlineSeries.Action.MAIN_MENU:
			series.end()
			ended = true
			return true
	return false

func _reset_for_new_series() -> void:
	queue.clear(); prediction.clear(); interpolation.clear(); _host_remote_buffer.clear()
	_visual_events.clear(); events.clear(); course.reset_world()
	round_id = series.round_generation; winner = 0; finish_deadline = -1; round_complete = false
	deaths = [0, 0]; finish_times = [-1, -1]; progress = [0, 0]
	barrier.arm(course.actors, [&"1", &"2"]); _hint_ticks = 0
	for i: int in 2: epochs[i] += 1
	loaded_revision += 1
	series.confirm_loaded(1, series.series_generation, series.round_generation,
		series.map_id, series.map_version, series.map_checksum, loaded_revision)

func _ready() -> void:
	process_physics_priority = 0
	queue.config = config
	prediction.config = config
	interpolation.config = config
	_host_remote_buffer.config = config
	add_child(barrier)
	barrier.arm(course.actors, [&"1", &"2"])
	if not series.configure(course.definition, configured_rounds):
		push_error("Invalid immutable online series settings")
		ended = true
		return
	round_id = series.round_generation
	loaded_revision = 1
	if host:
		series.confirm_loaded(1, series.series_generation, series.round_generation,
			series.map_id, series.map_version, series.map_checksum, loaded_revision)
	if host:
		session_id = Crypto.new().generate_random_bytes(16).hex_encode()
		reconnect_token = Crypto.new().generate_random_bytes(16).hex_encode()
		for i: int in 2:
			course.actors[i].died.connect(_death.bind(i))
			course.actors[i].relocated.connect(_respawn.bind(i))
			course.lives[i].checkpoint_activated.connect(_checkpoint.bind(i))
			course.lives[i].completed.connect(_finish.bind(i))
			course.lives[i].notification.connect(_lifecycle_notice.bind(i))
		course.world_event.connect(_world_event)
	apply_profiles()

func notify(message: String) -> void:
	status = message
	status_changed.emit(message)

func send(kind: NetPacket.Kind, data: Array = []) -> void:
	if OS.is_debug_build() and kind == NetPacket.Kind.PING:
		_ping_times[int(data[0])] = Time.get_ticks_usec()
		while _ping_times.size() > 32: _ping_times.erase(_ping_times.keys()[0])
	var packet := NetPacket.make(kind, session_id, host_tick, data)
	if OS.is_debug_build() and kind == NetPacket.Kind.SNAPSHOT and not _reported_invalid_snapshot \
		and NetPacket.decode(packet.encode(config), config) == null:
		_reported_invalid_snapshot = true
		print("M21_INVALID_SNAPSHOT size=", packet.encode(config).size(),
			" race_valid=", RaceBaseline.valid(data[10]),
			" series_valid=", OnlineSeries.valid(data[10][8]), " baseline=", data[10])
	transport.send(packet)

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
				course.definition.declared_checksum, profile, reconnect_token,
				BuildInfo.NETWORK_WIRE_REVISION, BuildInfo.BUILD_NUMBER]))
		elif joined:
			send(NetPacket.Kind.PING, [service_tick])
	if host:
		advance_host()
	else:
		advance_client()
	course.update_spectator(winner, round_complete)

func receive(packet: NetPacket) -> void:
	packet_counts[packet.kind] = int(packet_counts.get(packet.kind, 0)) + 1
	# Enforce codec even for injected/custom transports. Direction precedes heartbeat/state mutation.
	if NetPacket.decode(packet.encode(config), config) == null:
		scope_rejections += 1
		return
	if (host and packet.kind in [NetPacket.Kind.WELCOME, NetPacket.Kind.SNAPSHOT]) \
		or (not host and packet.kind in [NetPacket.Kind.HELLO, NetPacket.Kind.READY,
			NetPacket.Kind.INPUT, NetPacket.Kind.LOADED, NetPacket.Kind.SERIES_ACTION]):
		scope_rejections += 1
		return
	if packet.kind not in [NetPacket.Kind.INPUT, NetPacket.Kind.SNAPSHOT]:
		if service_tick - _intent_window >= 60:
			_intent_window = service_tick
			_intent_count = 0
		_intent_count += 1
		if _intent_count > 90:
			scope_rejections += 1
			return
	if host and packet.kind == NetPacket.Kind.HELLO:
		var data: Array = packet.data
		if data[0] != course.definition.map_id or int(data[1]) != course.definition.map_version \
			or data[2] != course.definition.declared_checksum \
			or int(data[5]) != BuildInfo.NETWORK_WIRE_REVISION \
			or int(data[6]) != BuildInfo.BUILD_NUMBER:
			scope_rejections += 1
			notify("Incompatible map ID/version/checksum")
			return
		if (paused or joined) and data[4] != reconnect_token:
			# HELLO retransmission before the first WELCOME needs no token.
			if paused or barrier.gate.start_tick >= 0:
				return
		if paused and data[4] == reconnect_token:
			joined = true
			last_packet_tick = service_tick
			send(NetPacket.Kind.WELCOME, [reconnect_token, config.snapshot_hz, profile, guest_profile,
				series.rounds_total, series.series_generation, series.settings_identity,
				BuildInfo.NETWORK_WIRE_REVISION, BuildInfo.BUILD_NUMBER])
			return
		if not joined and not paused:
			guest_profile = data[3].duplicate()
		joined = true
		last_packet_tick = service_tick
		send(NetPacket.Kind.WELCOME, [reconnect_token, config.snapshot_hz, profile, guest_profile,
			series.rounds_total, series.series_generation, series.settings_identity,
			BuildInfo.NETWORK_WIRE_REVISION, BuildInfo.BUILD_NUMBER])
		apply_profiles()
		return
	if not host and packet.kind == NetPacket.Kind.WELCOME and not joined:
		if not session_id.is_empty() and packet.session != session_id:
			return
		var reconnecting: bool = not reconnect_token.is_empty()
		session_id = packet.session
		reconnect_token = packet.data[0]
		config.snapshot_hz = int(packet.data[1])
		guest_profile = packet.data[2].duplicate()
		configured_rounds = int(packet.data[4])
		if int(packet.data[7]) != BuildInfo.NETWORK_WIRE_REVISION \
			or int(packet.data[8]) != BuildInfo.BUILD_NUMBER \
			or (not reconnecting and not series.configure(course.definition, configured_rounds, int(packet.data[5]))) \
			or (reconnecting and (int(packet.data[5]) != series.series_generation \
				or configured_rounds != series.rounds_total)) \
			or packet.data[6] != series.settings_identity:
			notify("Incompatible series settings")
			return
		joined = true
		host_tick = packet.tick
		client_tick = packet.tick
		last_packet_tick = service_tick
		course.actors[1].start_blocked = true
		apply_profiles()
		if reconnecting:
			send(NetPacket.Kind.READY, [true, ready_revision,
				series.series_generation, series.round_generation])
		else:
			loaded_revision += 1
			series.confirm_loaded(2, series.series_generation, series.round_generation,
				series.map_id, series.map_version, series.map_checksum, loaded_revision)
			_send_loaded()
		notify("Handshake accepted; load/hints then ready")
		return
	if not joined or packet.session != session_id:
		scope_rejections += 1
		return
	# Heartbeat age advances only for directionally valid packets.
	match packet.kind:
		NetPacket.Kind.LOADED:
			if host and packet.data[6] and series.confirm_loaded(2, int(packet.data[0]),
					int(packet.data[1]), packet.data[2], int(packet.data[3]), packet.data[4],
					int(packet.data[5])):
				last_packet_tick = service_tick
		NetPacket.Kind.READY:
			if host:
				if int(packet.data[2]) != series.series_generation \
					or int(packet.data[3]) != series.round_generation:
					scope_rejections += 1
					return
				if int(packet.data[1]) < _accepted_ready_revision:
					scope_rejections += 1
					return
				if int(packet.data[1]) == _accepted_ready_revision:
					return
				_accepted_ready_revision = int(packet.data[1])
				guest_ready = packet.data[0]
				last_packet_tick = service_tick
				if paused and guest_ready:
					queue.clear()
					var target: Vector2 = course.lives[1].respawn_position
					if not RespawnSafety.valid(course.actors[1], target):
						target = course.lives[1].start_position
					if not RespawnSafety.valid(course.actors[1], target):
						return
					course.actors[1].respawn_at(target, true)
					if finish_times[1] >= 0:
						course.actors[1].finish_run()
					for i: int in 2:
						course.actors[i].start_blocked = _paused_blocks[i]
					paused = false
					reconnect_remaining = 0
					series.resume_reconnect()
					emit_event(0, GameplayEvents.Kind.RESUME)
					notify("Guest returned; match resumed")
				else:
					if not series.set_ready(2, guest_ready, int(packet.data[2]),
							int(packet.data[3]), int(packet.data[1])):
						scope_rejections += 1
		NetPacket.Kind.INPUT:
			if host and not paused:
				last_packet_tick = service_tick
				var command: InputCommand = InputCommand.decode(packet.data)
				if command.generation == epochs[1] \
					and command.series_generation == series.series_generation \
					and command.round_generation == series.round_generation \
					and series.phase in [OnlineSeries.Phase.RACING, OnlineSeries.Phase.FINISH_WINDOW]:
					if queue.accept(command, host_tick, service_tick):
						client_tick = command.tick
				else:
					scope_rejections += 1
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
				var echo: int = int(packet.data[0])
				if _ping_times.has(echo):
					measured_rtt_ms = (Time.get_ticks_usec() - int(_ping_times[echo])) / 1000.0
					_ping_times.erase(echo)
					last_pong_service = service_tick
		NetPacket.Kind.BYE:
			disconnected()
		NetPacket.Kind.SERIES_ACTION:
			# A guest may request presentation navigation, but can never mutate host series authority.
			scope_rejections += 1

func _send_loaded() -> void:
	if not host and joined:
		send(NetPacket.Kind.LOADED, [series.series_generation, series.round_generation,
			series.map_id, series.map_version, series.map_checksum, loaded_revision, true])

func sample_input() -> InputFrame:
	if input_provider.is_valid():
		return input_provider.call() as InputFrame
	return input_layer.sample() if input_layer != null else InputFrame.new()

func advance_host() -> void:
	if paused:
		reconnect_remaining -= 1
		if reconnect_remaining <= 0:
			if series.award_guest_disconnect(progress, _checkpoint_evidence()):
				_sync_series_fields()
				emit_event(1, GameplayEvents.Kind.WINNER)
				_results_enter_tick = host_tick
				notify("Reconnect window expired; host wins round")
			paused = false
		return
	host_tick += 1
	if joined and series.phase == OnlineSeries.Phase.SYNCHRONIZED_LOADING and series.both_loaded():
		series.begin_hint(host_tick, config.hint_ticks)
		notify("Controls")
	if series.phase == OnlineSeries.Phase.CONTROLS_HINT:
		_hint_ticks = maxi(0, config.hint_ticks - (series.hint_end_tick - host_tick))
		if host_tick >= series.hint_end_tick:
			barrier.gate.set_ready(&"1", true)
			barrier.gate.set_ready(&"2", true)
			var authoritative_start: int = host_tick + config.countdown_ticks
			if barrier.gate.schedule(authoritative_start, host_tick):
				series.begin_countdown(authoritative_start, host_tick)
	if series.phase == OnlineSeries.Phase.COUNTDOWN and barrier.advance(host_tick):
		series.begin_race(host_tick)
		_round_started_clock = clock_ticks
		emit_event(0, GameplayEvents.Kind.START)
		notify("GO")
	if series.phase in [OnlineSeries.Phase.RACING, OnlineSeries.Phase.FINISH_WINDOW]:
		clock_ticks += 1
		course.advance_world(true)
		var frames: Array[InputFrame] = [sample_input(), queue.consume()]
		last_simulated_sequence = queue.ack
		for i: int in 2:
			course.actors[i].advance(frames[i] if series.current_finish_times[i] < 0 else InputFrame.new())
			update_support(i)
			movement_events(i)
		course.advance_world(false)
		for i: int in 2: progress[i] = course.lives[i].progress.reached.size()
		if series.expire_finish_window(clock_ticks, progress, _checkpoint_evidence()):
			for actor: PlayerController in course.actors:
				actor.start_blocked = true
			_sync_series_fields()
			_results_enter_tick = host_tick
			notify("Round complete")
	else:
		queue.consume()
	if series.phase == OnlineSeries.Phase.ROUND_RESULTS and _results_enter_tick >= 0 \
		and host_tick > _results_enter_tick:
		series.enter_between_round()
		_sync_series_fields()
	if series.phase == OnlineSeries.Phase.BETWEEN_ROUND_READY and series.both_ready():
		_begin_next_round()
	if phase() != _previous_phase:
		_previous_phase = phase()
		if _previous_phase in [OnlineSeries.Phase.ROUND_RESULTS,
			OnlineSeries.Phase.BETWEEN_ROUND_READY, OnlineSeries.Phase.FINAL_SERIES_RESULTS]:
			guest_ready = false
		emit_event(0, GameplayEvents.Kind.ROUND_TRANSITION, _previous_phase)
	if joined and service_tick % (60 / config.snapshot_hz) == 0:
		events.prune(host_tick, config.event_lifetime)
		var states: Array = []
		for i: int in 2:
			states.append(ActorState.capture(course.actors[i], epochs[i]).values())
			progress[i] = course.lives[i].progress.reached.size()
		send(NetPacket.Kind.SNAPSHOT, [queue.ack, clock_ticks, barrier.gate.start_tick, paused,
			states, course.capture_dynamics(), events.recent, winner, reconnect_remaining, progress,
			RaceBaseline.capture(self)])
		snapshot_count += 1
		last_snapshot_service = service_tick
		_host_remote_buffer.insert(host_tick, ActorState.capture(course.actors[1], epochs[1]))
	var remote_sample: Dictionary = _host_remote_buffer.sample(host_tick - config.interpolation_ticks)
	if not remote_sample.is_empty():
		course.remote.presentation.position = remote_sample.position - course.remote.position
		course.remote.presentation.present(remote_sample.state.visual(
			visual_events_at(host_tick - config.interpolation_ticks)))

func _checkpoint_evidence() -> Array:
	var result: Array = [[], []]
	for i: int in 2:
		for id: StringName in course.lives[i].progress.reached:
			result[i].append(course.lives[i].progress.ordered_ids.find(id))
	return result

func _sync_series_fields() -> void:
	round_id = series.round_generation
	winner = series.current_winner
	finish_deadline = series.finish_deadline
	finish_times.assign(series.current_finish_times)
	progress.assign(series.current_progress)
	round_complete = series.phase in [OnlineSeries.Phase.ROUND_RESULTS,
		OnlineSeries.Phase.BETWEEN_ROUND_READY, OnlineSeries.Phase.FINAL_SERIES_RESULTS]

func advance_client() -> void:
	if not joined:
		return
	if series.phase == OnlineSeries.Phase.SYNCHRONIZED_LOADING and service_tick % 30 == 0:
		_send_loaded()
	if series.phase == OnlineSeries.Phase.BETWEEN_ROUND_READY and guest_ready and service_tick % 30 == 0:
		send(NetPacket.Kind.READY, [true, ready_revision,
			series.series_generation, series.round_generation])
	if paused:
		return
	client_tick += 1
	var age: int = service_tick - last_snapshot_service
	var estimated: int = host_tick + mini(age, config.extrapolation_ticks)
	var actor: PlayerController = course.actors[1]
	if remote_phase == OnlineSeries.Phase.COUNTDOWN and series.start_tick >= 0 \
		and estimated >= series.start_tick:
		# Presentation/prediction derives from the replicated host tick; the host still
		# validates every command and remains the only gameplay authority.
		remote_phase = OnlineSeries.Phase.RACING
		actor.start_blocked = false
		clock_ticks = maxi(clock_ticks, estimated - series.start_tick + 1)
	if not _dynamics.is_empty():
		course.apply_dynamics(_dynamics, mini(age, config.extrapolation_ticks))
	if not actor.start_blocked:
		var command := InputCommand.new()
		sequence = NetSequence.next(sequence)
		command.sequence = sequence
		command.tick = estimated
		command.generation = maxi(0, prediction.epoch)
		command.series_generation = series.series_generation
		command.round_generation = series.round_generation
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
	var incoming_series: Array = packet.data[10][8] if packet.data.size() == 11 \
		and packet.data[10] is Array and packet.data[10].size() == 9 else []
	if packet.tick <= last_snapshot_tick or not course.valid_dynamics(packet.data[5]) \
		or incoming_series.is_empty() \
		or int(incoming_series[0]) < series.series_generation \
		or (int(incoming_series[0]) == series.series_generation \
			and int(incoming_series[1]) < series.round_generation) \
		or not RaceBaseline.matches_map(packet.data[10], course.definition):
		scope_rejections += 1
		return
	if last_snapshot_tick >= 0:
		telemetry.add("snapshot_gap_ticks", packet.tick - last_snapshot_tick)
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
	var old_phase: int = remote_phase
	var old_round: int = round_id
	var old_series: int = series.series_generation
	RaceBaseline.apply(packet.data[10], self)
	if round_id != old_round or series.series_generation != old_series:
		course.reset_world()
		prediction.metrics.reset_window(round_id)
		sequence = 65535
		prediction.clear()
		interpolation.clear()
		_visual_events.clear()
		loaded_revision += 1
		series.loaded[1] = true
		series.loaded_revisions[1] = loaded_revision
		_send_loaded()
	if remote_phase in [OnlineSeries.Phase.ROUND_RESULTS,
		OnlineSeries.Phase.BETWEEN_ROUND_READY, OnlineSeries.Phase.FINAL_SERIES_RESULTS] \
		and old_phase != remote_phase:
		guest_ready = false
		ready_revision += 1
	for i: int in course.checkpoints.size():
		course.checkpoints[i].local_active = course.definition.checkpoint_ids[i] in course.lives[1].progress.reached
		course.checkpoints[i].queue_redraw()
	_dynamics = packet.data[5].duplicate(true)
	course.apply_dynamics(_dynamics)
	var own: ActorState = ActorState.decode(packet.data[4][1])
	prediction.reconcile(own, int(packet.data[0]), course.actors[1])
	interpolation.insert(packet.tick, ActorState.decode(packet.data[4][0]))
	snapshot_count += 1
	for event: Array in events.ingest(packet.data[6], packet.tick, config.event_lifetime):
		if int(event[5]) != round_id:
			continue
		event_received.emit(event)
		if int(event[2]) == 1:
			_visual_events.append(event)
		if int(event[3]) == GameplayEvents.Kind.START:
			notify("GO")
		elif int(event[3]) == GameplayEvents.Kind.RESUME:
			notify("Match resumed")
		elif int(event[3]) == GameplayEvents.Kind.FINISH:
			notify("Player %d finished; winner %d" % [int(event[2]), winner])
		elif int(event[3]) == GameplayEvents.Kind.SKIPPED_CHECKPOINT:
			notify("Player %d: skipped mandatory checkpoint" % int(event[2]))

func movement_events(index: int) -> void:
	var bits: int = course.actors[index].motor.events
	for kind: int in range(5):
		if bits & movement_bit(kind):
			emit_event(index + 1, kind as GameplayEvents.Kind)

static func movement_bit(kind: int) -> int:
	return [1, 2, 4, 8, 32][kind] if kind >= 0 and kind < 5 else 0

func emit_event(player_id: int, kind: GameplayEvents.Kind, detail: int = 0) -> void:
	events.round_id = round_id
	var generation: int = 0
	if kind in [GameplayEvents.Kind.TURRET_FIRE, GameplayEvents.Kind.PROJECTILE_HIT,
		GameplayEvents.Kind.POOL_RETURN] and detail < course.dynamics.size():
		generation = course.dynamics[detail].generation
	events.emit_event(host_tick, player_id, kind, detail, generation)
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
	deaths[index] += 1
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
	var was_winner: int = series.current_winner
	if not series.record_finish(index + 1, clock_ticks - _round_started_clock,
			course.lives[index].progress.reached.size(), _checkpoint_evidence()[index], clock_ticks):
		scope_rejections += 1
		return
	_sync_series_fields()
	epochs[index] += 1
	course.actors[index].start_blocked = true
	emit_event(index + 1, GameplayEvents.Kind.FINISH)
	if was_winner == 0:
		emit_event(index + 1, GameplayEvents.Kind.WINNER)
		notify("Round winner: player %d; 30 seconds remain" % winner)
	elif series.phase == OnlineSeries.Phase.ROUND_RESULTS:
		_results_enter_tick = host_tick
		notify("Both players finished")

func _lifecycle_notice(key: String, index: int) -> void:
	if key == "M7_SKIPPED_CHECKPOINT":
		emit_event(index + 1, GameplayEvents.Kind.SKIPPED_CHECKPOINT)
		notify("Player %d: skipped mandatory checkpoint" % (index + 1))

func _world_event(player_id: int, kind: int, object_id: int) -> void:
	if kind == GameplayEvents.Kind.JUMP_PAD and player_id in [1, 2]:
		epochs[player_id - 1] += 1
		if player_id == 2:
			queue.pending.clear()
	emit_event(player_id, kind as GameplayEvents.Kind, object_id)

func disconnected() -> void:
	if not joined:
		return
	joined = false
	prediction.clear()
	interpolation.clear()
	queue.clear()
	_hint_ticks = 0
	if host:
		if series.phase in [OnlineSeries.Phase.FINAL_SERIES_RESULTS, OnlineSeries.Phase.LOBBY]:
			notify("Guest left after series completion")
			return
		paused = true
		series.enter_reconnect()
		for i: int in 2:
			_paused_blocks[i] = course.actors[i].start_blocked
			course.actors[i].start_blocked = true
		reconnect_remaining = config.reconnect_ticks
		emit_event(0, GameplayEvents.Kind.DISCONNECT)
		notify("Guest disconnected; match paused for 45 seconds")
	else:
		ended = true
		series.end()
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
	_ping_times.clear()
	if is_instance_valid(course) and is_instance_valid(course.world):
		for projectile: HazardProjectile in course.world.projectiles:
			projectile.recycle()
	if transport != null:
		if joined:
			send(NetPacket.Kind.BYE)
		transport.close()
	joined = false
	ended = true
	series.end()
	queue.clear()
	prediction.clear()
	interpolation.clear()
	_host_remote_buffer.clear()
	events.clear()
	_dynamics.clear()
	_visual_events.clear()
	barrier.actors.clear()

func prepare_reconnect() -> void:
	_ping_times.clear()
	last_pong_service = -1000
	# Explicit same-process retry retains only the ephemeral bearer token, never a nickname identity.
	if host:
		return
	joined = false
	ended = false
	paused = false
	sequence = 65535
	ready_revision += 1
	# F9 confirms return/load even if Results or a withdrawal had cleared race Ready.
	guest_ready = true
	_hint_ticks = 0
	prediction.clear()
	interpolation.clear()
	_dynamics.clear()
	course.actors[1].start_blocked = true
	notify("Reconnecting to the same local session")

func _exit_tree() -> void:
	shutdown()
