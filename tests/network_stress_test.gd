extends SceneTree
var failures: int = 0

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		push_error("M17: " + label)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for name_value: String in NetworkConditionProfile.NAMES:
		check(NetworkConditionProfile.preset(name_value).valid(), "preset valid " + name_value)
	check(NetworkConditionProfile.from_dictionary({"id": "combined", "one_way_ms": 75.0, "outbound_loss": 0.2}).valid(), "data-driven profile")
	for data: Dictionary in [{"one_way_ms": "75"}, {"seed_value": 1.5}, {"unexpected": 1}, {"jitter_ms": INF}, {"jitter_distribution": "bad"}, {"disconnect_tick": -2}, {"reconnect_after_ticks": 2701}]:
		check(NetworkConditionProfile.from_dictionary(data) == null, "invalid data profile rejected")
	var profile := NetworkConditionProfile.preset("combined")
	for invalid: float in [NAN, INF, -1, 1001]:
		profile.one_way_ms = invalid
		check(not profile.valid(), "finite/ranged latency")
	profile = NetworkConditionProfile.preset("combined")
	for invalid: float in [NAN, INF, -0.1, 1.1]:
		profile.outbound_loss = invalid
		check(not profile.valid(), "loss probability validation")
	check(not NetworkConditionProfile.preset("unknown").valid(), "unknown profile rejected")
	for milliseconds: float in [0, 40, 75, 100, 125]:
		var emulator := NetworkEmulator.new()
		var sum: int = 0
		for index: int in 1000: sum += emulator.quantize_ms(milliseconds)
		check(absf(sum * 1000.0 / 60000 - milliseconds) < 0.02, "exact mean ms across ticks")
	var first := NetworkEmulator.new()
	var second := NetworkEmulator.new()
	first.configure("combined", 12345)
	second.configure("combined", 12345)
	var a: Array = []
	var b: Array = []
	for tick: int in 900:
		if tick < 600:
			var packet := NetPacket.make(NetPacket.Kind.PING, "a".repeat(32), tick, [tick])
			first.enqueue(packet, tick)
			second.enqueue(packet, tick)
			first.send(packet)
			second.send(packet)
		for packet: NetPacket in first.poll(tick): a.append([tick, packet.tick])
		for packet: NetPacket in second.poll(tick): b.append([tick, packet.tick])
	check(a == b and first.report() == second.report(), "same seed/input impairment trace and counters")
	check(first.pending.is_empty() and first.dropped > 0, "loss and eventual drain")
	for action: String in ["dropped", "duplicated", "reordered"]:
		check(first.counters.get("in/PING/" + action, 0) > 0, "direction counters " + action)
	check(first.counters.get("out/PING/dropped", 0) > 0, "independent outbound loss")
	var packet := NetPacket.make(NetPacket.Kind.PING, "a".repeat(32), 0, [0])
	first.configure("rtt250", 15)
	for index: int in 1000: first.enqueue(packet, 0)
	check(first.pending.size() == 256, "queue cap")
	var previous: Dictionary = first.report()
	check(not first.configure("bad", -1) and previous == first.report(), "invalid apply atomic")
	first.poll(1000)
	check(first.pending.is_empty(), "expired queue drained")
	first.enqueue(packet, 1001)
	first.disconnect_at = 1002
	first.poll(1002)
	check(first.pending.is_empty() and not first.connected, "scheduled disconnect teardown")
	first.enqueue(packet, 1003)
	check(first.pending.is_empty(), "closed queue rejects packets")
	first.reopen()
	first.enqueue(packet, 1004)
	check(not first.pending.is_empty(), "reopen")
	first.close()
	for iteration: int in 100:
		first.reopen()
		first.configure("rtt250", iteration)
		first.enqueue(packet, iteration)
		first.configure("clean", iteration)
		check(first.pending.size() == 1, "profile apply retains pending packet")
		first.poll(iteration + 20)
		first.close()
		check(first.pending.is_empty(), "repeated profile/reconnect cleanup")
	var recovery := NetworkTelemetry.new()
	recovery.observe_connection(false, 0, 0)
	recovery.observe_connection(true, 10, 1000)
	recovery.observe_connection(false, 20, 10000)
	recovery.observe_connection(false, 30, 50000)
	recovery.observe_connection(true, 80, 1210000)
	check(recovery.reconnects_completed == 1 and recovery.metric("reconnect_service_ms").current == 1000 and recovery.metric("reconnect_wall_ms").current == 1200, "separate service/wall reconnect duration")
	var telemetry := NetworkTelemetry.new()
	for value: int in 1000: telemetry.add("test", value)
	check(telemetry.metric("test").count == 300 and telemetry.metric("test").p95 == 984, "bounded nearest-rank percentile")
	telemetry.add("test", NAN)
	check(telemetry.metric("test").count == 300, "reject nonfinite telemetry")
	for index: int in 120: telemetry.update_warning(200)
	check(not telemetry.warning, "equal 200 no warning")
	for index: int in 29: telemetry.update_warning(201)
	check(not telemetry.warning, "warning debounce")
	telemetry.update_warning(201)
	check(telemetry.warning, "above 200 warning")
	for index: int in 120: telemetry.update_warning(190)
	check(telemetry.warning, "hysteresis dead band")
	for index: int in 59: telemetry.update_warning(180)
	check(telemetry.warning, "clear debounce")
	telemetry.update_warning(180)
	check(not telemetry.warning, "clear at 180 after second")
	check(NetworkTelemetry.band(80) == "near_ideal" and NetworkTelemetry.band(150) == "comfortable" and NetworkTelemetry.band(200) == "playable" and NetworkTelemetry.band(201) == "warning", "quality boundaries")
	telemetry.reset_window(2)
	check(telemetry.samples.is_empty() and telemetry.round_id == 2, "round reset")
	check(JSON.parse_string(JSON.stringify(telemetry.report())).schema == 1, "JSON schema")
	var buffer := SnapshotBuffer.new()
	buffer.sample(0)
	check(buffer.underflow == 1, "interpolation underflow")
	await prediction_tests()
	if failures == 0: print("PROJECTVELOCITY_M17_STRESS_OK")
	quit(0 if failures == 0 else 1)

func prediction_tests() -> void:
	var course := NetworkCourse.new()
	root.add_child(course)
	await physics_frame
	var actor: PlayerController = course.actors[1]
	var history := PredictionHistory.new()
	var state := ActorState.capture(actor, 1)
	history.reconcile(state, 0, actor)
	check(history.lifecycle_rebases == 1 and history.metrics.metric("ordinary_error_px").count == 0, "lifecycle excluded")
	state.blocked = false
	history.injected_pending = true
	actor.position.x += 180
	history.reconcile(state, 0, actor)
	check(history.injected_corrections == 1 and history.metrics.metric("ordinary_error_px").count == 0, "injection excluded")
	actor.position.x += 4
	history.reconcile(state, 0, actor)
	check(actor.position.distance_to(state.position) < 0.01, "eventual actor convergence")
	check(history.ordinary_corrections == 1 and history.metrics.metric("ordinary_error_px").count == 1, "ordinary error measured")
	var buffer := SnapshotBuffer.new()
	buffer.insert(10, state)
	buffer.sample(11)
	buffer.sample(30)
	check(buffer.extrapolated == 1 and buffer.held == 1, "bounded extrapolation then hold")
	state.state = 9
	buffer.sample(11)
	check(buffer.held == 2, "finished actor holds instead of extrapolating")
	course.queue_free()
	await process_frame
