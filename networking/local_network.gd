extends Node
## Explicit development composition root. No SaveStore / TrialRecords and no persistent UUID on wire.

var session: NetworkSession
var course: NetworkCourse
var hud: Label
var countdown: Label
var automated: bool = false
var limit: int = 0
var injected: bool = false
var event_counts: Dictionary = {}
var _previous_remote := Vector2.ZERO
var _remote_motion: float = 0
var _previous_clock: int = 0
var _clock_monotonic: bool = true
var _screenshots: int = 0
var _retry_port: int = 24715
var _last_physics_usec: int = 0
var _maximum_physics_gap_usec: int = 0
var race_fixture := NetworkRaceFixture.new()
var _race_captures: Dictionary = {}
var _last_start_status: String = ""
var selected_profile: int = 0
var scheduled_reconnect: int = -1
var profile_changes: int = 0
var warning_label: Label

func option(key: String, fallback: String = "") -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--" + key + "="):
			return argument.substr(key.length() + 3)
	return fallback

func _ready() -> void:
	if not OS.is_debug_build():
		get_tree().quit(1)
		return
	process_physics_priority = 90
	var role: String = option("role", "host")
	var port: int = int(option("port", "24715"))
	_retry_port = port
	if role not in ["host", "client"] or port < 1024 or port > 65535:
		push_error("Local Network requires role=host/client and port 1024..65535")
		get_tree().quit(1)
		return
	if option("map") not in ["", "training", "industrial"]:
		push_error("Local Network requires map=training or map=industrial")
		get_tree().quit(1)
		return
	automated = option("auto", "false") == "true"
	limit = int(option("ticks", "0"))
	var input := InputLayer.new()
	add_child(input)
	var runtime := SettingsRuntime.new()
	add_child(runtime)
	var settings: Dictionary = SaveSchema.defaults().settings
	runtime.apply(settings)
	course = NetworkCourse.new()
	course.host = role == "host"
	course.definition = MapCatalog.industrial() if option("map") == "industrial" else MapCatalog.training()
	runtime.world.viewport.add_child(course)
	if not course.diagnostics.valid():
		push_error("Network map validation failed")
		get_tree().quit(1)
		return
	var config := NetworkConfig.new()
	config.snapshot_hz = int(option("snapshots", "20"))
	config.timeout_ticks = int(option("timeout-ticks", "180"))
	if not config.valid():
		get_tree().quit(1)
		return
	var local := LocalENetTransport.new()
	local.config = config
	if local.open(course.host, port) != OK:
		push_error(local.error)
		get_tree().quit(1)
		return
	var emulator := NetworkEmulator.new()
	emulator.inner = local
	emulator.config = config
	for numeric_option: String in ["seed", "drop-at", "drop-duration"]:
		if not option(numeric_option, "0").is_valid_int():
			push_error("Invalid integer in network profile")
			get_tree().quit(1)
			return
	var condition := NetworkConditionProfile.preset(option("emulation", "clean"), int(option("seed", "15")))
	condition.disconnect_tick = int(option("drop-at", "-1"))
	condition.reconnect_after_ticks = int(option("drop-duration", "45"))
	if not option("condition-file").is_empty():
		var source := FileAccess.open(option("condition-file"), FileAccess.READ)
		var data: Variant = null
		if source != null and source.get_length() <= 4096: data = JSON.parse_string(source.get_as_text())
		condition = NetworkConditionProfile.from_dictionary(data) if data is Dictionary else null
	if condition == null or not emulator.apply_profile(condition):
		push_error("Invalid network condition profile")
		get_tree().quit(1)
		return
	selected_profile = NetworkConditionProfile.NAMES.find(condition.id)
	session = NetworkSession.new()
	session.host = course.host
	session.course = course
	session.config = config
	session.transport = emulator
	session.input_layer = input
	course.actors[0 if course.host else 1].input_layer = input
	session.profile = ["Host" if course.host else "Guest", "44cceeff" if course.host else "dd88ffff", "ffffffff"]
	if automated:
		session.input_provider = bot_input
	session.event_received.connect(func(event: Array) -> void:
		var key: String = GameplayEvents.Kind.keys()[int(event[3])]
		event_counts[key] = int(event_counts.get(key, 0)) + 1)
	session.status_changed.connect(func(message: String) -> void: print("M15_STATUS ", role, " ", message))
	add_child(session)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.05, 0.92)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	canvas.add_child(panel)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 20)
	panel.add_child(hud)
	countdown = Label.new()
	countdown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	countdown.add_theme_font_size_override("font_size", 204)
	countdown.add_theme_color_override("font_color", Color("f5fbff"))
	countdown.add_theme_color_override("font_outline_color", Color("101c26"))
	countdown.add_theme_constant_override("outline_size", 16)
	canvas.add_child(countdown)
	countdown.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	countdown.hide()
	warning_label = Label.new()
	warning_label.position = Vector2(24, 400)
	warning_label.add_theme_font_size_override("font_size", 20)
	warning_label.add_theme_color_override("font_color", Color("ffcc55"))
	warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	warning_label.add_theme_constant_override("outline_size", 6)
	canvas.add_child(warning_label)
	DisplayServer.window_set_title("ProjectVelocity M17 Local Network — " + role)
	var size_parts: PackedStringArray = option("capture-size", "1280x800").split("x")
	if size_parts.size() == 2 and option("capture-size", "1280x800") in ["1280x800", "1920x1080"]:
		DisplayServer.window_set_size(Vector2i(int(size_parts[0]), int(size_parts[1])))
	print("M15_READY role=", role, " protocol=", config.protocol,
		" wire=", BuildInfo.NETWORK_WIRE_REVISION, " map=", course.definition.map_id)

func bot_input() -> InputFrame:
	var frame := InputFrame.new()
	if option("race") == "true" and not session.host and session.clock_ticks >= 70:
		return frame
	var tick: int = session.clock_ticks if session.host else session.client_tick
	var actor: PlayerController = course.actors[0 if session.host else 1]
	var offset: float = actor.position.x - course.lives[0].start_position.x
	# Independent streams stay near Start, exercise actual collision, jump, Dash and remote motion.
	frame.movement.x = 1.0 if offset < (220 if session.host else 360) else -1.0
	frame.jump_pressed = tick % (83 if session.host else 107) == 0
	frame.jump_held = tick % (83 if session.host else 107) < 15
	frame.dash_pressed = tick % (139 if session.host else 157) == 0
	frame.dash_direction = Vector2(frame.movement.x, 0)
	return frame

func _physics_process(_delta: float) -> void:
	if session == null:
		return
	update_countdown()
	session.telemetry.observe(session)
	var condition: NetworkConditionProfile = (session.transport as NetworkEmulator).profile
	if condition.disconnect_tick >= 0 and session.service_tick == condition.disconnect_tick:
		session.disconnected()
		if not session.host: scheduled_reconnect = session.service_tick + condition.reconnect_after_ticks
	if scheduled_reconnect == session.service_tick:
		retry_connection()
		scheduled_reconnect = -1
	if option("profile-change") == "true":
		if session.service_tick == 800: apply_selected_profile("rtt250")
		if session.service_tick == 1000: apply_selected_profile("clean")
	var now: int = Time.get_ticks_usec()
	if _last_physics_usec > 0:
		_maximum_physics_gap_usec = maxi(_maximum_physics_gap_usec, now - _last_physics_usec)
	_last_physics_usec = now
	if automated and not session.host and option("reconnect") == "true":
		var disconnect_tick: int = int(option("disconnect-tick", "700"))
		if session.service_tick == disconnect_tick:
			session.transport.close()
			session.disconnected()
		elif session.service_tick == disconnect_tick + 45:
			retry_connection()
	if automated and session.host and option("lifecycle") == "true":
		lifecycle_fixture()
	if automated and option("race") == "true":
		race_fixture.step(session)
	if automated and option("retry") == "true":
		race_fixture.retry(session)
	if automated and option("malicious") == "true":
		race_fixture.attack(session)
	_clock_monotonic = _clock_monotonic and session.clock_ticks >= _previous_clock
	_previous_clock = session.clock_ticks
	_remote_motion += course.remote.position.distance_to(_previous_remote)
	_previous_remote = course.remote.position
	if automated and not session.host and session.clock_ticks > 120 and not injected:
		session.prediction.injected_pending = true
		course.actors[1].position += Vector2(180, -40)
		injected = true
	var emulator: NetworkEmulator = session.transport as NetworkEmulator
	var hud_text: String = "M17 DEV • %s • round %d • %s\n%s" % [
		"HOST" if session.host else "CLIENT", session.round_id, RaceBaseline.Phase.keys()[session.phase()], start_status().left(85)]
	hud_text += "\nMeasured RTT %.1fms • estimated one-way %.1fms • clock %.3fs" % [
		session.measured_rtt_ms, session.measured_rtt_ms / 2, session.clock_ticks / 60.0]
	hud_text += "\n%s: simulated one-way %.1fms / RTT %.1fms • jitter ±%.1fms" % [
		condition.id, condition.one_way_ms, condition.one_way_ms * 2, condition.jitter_ms]
	hud_text += "\nLoss in/out %.0f/%.0f%% • queue %d/256 (peak %d)" % [
		condition.inbound_loss * 100, condition.outbound_loss * 100, emulator.pending.size(), emulator.queue_high_water]
	hud_text += "\nOrdinary error p95 %.2fpx • corrections %d • rebases %d" % [
		session.prediction.metrics.metric("ordinary_error_px").p95,
		session.prediction.ordinary_corrections, session.prediction.lifecycle_rebases]
	hud_text += "\nHistory %d/240 • interpolation %d/32 • snapshot age %d ticks" % [
		session.prediction.commands.size(), session.remote_buffer_depth(), session.service_tick - session.last_snapshot_service]
	hud_text += "\nProgress %s • pool %d/10 • rejects %d • Ready %s" % [
		str(session.progress), course.world.active_count(), session.scope_rejections, str(session.guest_ready)]
	hud_text += "\nF2 next [%s] • F3 apply • F4 clean • F5 metrics reset" % NetworkConditionProfile.NAMES[selected_profile]
	hud_text += "\nF6 Ready • F7 round retry • F8 drop • F9 reconnect"
	hud_text += "\nWASD / stick • Space / A Jump • Shift / RB Dash • no Solo records"
	hud.text = hud_text
	warning_label.text = ("Плохое соединение / Connection warning • measured RTT >200ms" if session.telemetry.warning else "")
	var current_start_status: String = start_status()
	if session.clock_ticks == 0 and current_start_status != _last_start_status:
		_last_start_status = current_start_status
		print("M16_START ", "host" if session.host else "client", " ", current_start_status)
	if automated and DisplayServer.get_name() != "headless" and session.clock_ticks > 120 \
		and _screenshots < 2 and session.service_tick % 120 == 0 and not option("evidence").is_empty():
		_screenshots += 1
		capture.call_deferred()
	if automated and option("race") == "true" and DisplayServer.get_name() != "headless" \
		and not option("evidence").is_empty():
		for tick: int in [145, 225, 320, 540, 760, 1150, 1450]:
			if session.clock_ticks >= tick and not _race_captures.has(tick):
				_race_captures[tick] = true
				_screenshots += 1
				capture.call_deferred()
		if session.round_complete and not _race_captures.has("results"):
			_race_captures["results"] = true
			_screenshots += 1
			capture.call_deferred()
	if limit > 0 and session.service_tick >= limit:
		finish_test()

func capture() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(option("evidence") + "-%d.png" % _screenshots)

func countdown_text() -> String:
	var remaining: int = session.barrier.gate.start_tick - session.host_tick
	return " • %d" % ceili(remaining / 60.0) if remaining > 0 else ""

func update_countdown() -> void:
	var remaining: int = session.barrier.gate.start_tick - session.host_tick
	var active: bool = session.joined and not session.paused and not session.ended \
		and session.barrier.gate.start_tick >= 0 and not session.round_complete
	countdown.text = ""
	if active and session.phase() == RaceBaseline.Phase.COUNTDOWN and remaining > 0:
		countdown.text = str(ceili(remaining / 60.0))
	elif active and session.phase() == RaceBaseline.Phase.RUNNING and remaining > -60:
		countdown.text = "GO"
	countdown.visible = not countdown.text.is_empty()

func start_status() -> String:
	if session.paused or session.ended or session.clock_ticks > 0 or session.round_complete:
		return session.status + countdown_text()
	if session.status.begins_with("Incompatible"):
		return session.status
	if not session.transport.connected:
		return ("Waiting for CLIENT" if session.host else "Connecting to HOST; F9 retries") \
			+ " at 127.0.0.1:%d — keep both windows open" % _retry_port
	if not session.joined:
		return "Peer connected; waiting for handshake"
	if not session.guest_ready:
		return "Guest is not ready — press F6 in the CLIENT window"
	if session.barrier.gate.start_tick >= 0:
		return "Starting" + countdown_text()
	if session._hint_ticks < session.config.hint_ticks:
		return "Preparing start • %ds" % ceili((session.config.hint_ticks - session._hint_ticks) / 60.0)
	return "Waiting for guest readiness" if session.host else "Ready sent; waiting for host countdown"

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or session == null:
		return
	if event.keycode == KEY_F2:
		selected_profile = (selected_profile + 1) % NetworkConditionProfile.NAMES.size()
	elif event.keycode == KEY_F3:
		apply_selected_profile(NetworkConditionProfile.NAMES[selected_profile])
	elif event.keycode == KEY_F4:
		apply_selected_profile("clean")
	elif event.keycode == KEY_F5:
		session.telemetry.reset_window(session.round_id)
		session.prediction.metrics.reset_window(session.round_id)
	elif event.keycode == KEY_F8:
		session.transport.close()
		session.disconnected()
	elif event.keycode == KEY_F9 and not session.host and not session.joined:
		retry_connection()
	elif event.keycode == KEY_F6 and not session.host:
		session.set_local_ready(not session.guest_ready)
	elif event.keycode == KEY_F7 and session.host:
		session.retry_round()

func apply_selected_profile(name_value: String) -> void:
	var emulator: NetworkEmulator = session.transport as NetworkEmulator
	if emulator.configure(name_value, emulator.profile.seed_value):
		profile_changes += 1
		selected_profile = NetworkConditionProfile.NAMES.find(name_value)

func retry_connection() -> void:
	var emulator: NetworkEmulator = session.transport as NetworkEmulator
	var local: LocalENetTransport = emulator.inner as LocalENetTransport
	if local.open(false, _retry_port) == OK:
		emulator.reopen()
		session.prepare_reconnect()

func lifecycle_fixture() -> void:
	# Host-only collision fixture, separately reported from ordinary movement acceptance.
	var actor: PlayerController = course.actors[1]
	if session.clock_ticks == 150:
		actor.respawn_at(course.definition.death_bounds.get_center(), true)
		actor.motor.invulnerability_ticks = 0
	elif session.clock_ticks >= 240 and (session.clock_ticks - 240) % 60 == 0:
		var index: int = (session.clock_ticks - 240) / 60
		if index < course.checkpoints.size():
			actor.respawn_at(course.checkpoints[index].position, true)
		elif index == course.checkpoints.size():
			actor.respawn_at(course.finish.position, true)

func finish_test() -> void:
	var success: bool = session.clock_ticks > 120 and _clock_monotonic and _remote_motion > 100
	if not session.host:
		success = success and session.snapshot_count > 50 and session.prediction.corrections > 0 \
			and session.prediction.hard_snaps > 1 and session.movement_samples > 30
	var report: Dictionary = {"role": "host" if session.host else "client", "ok": success,
		"clock": session.clock_ticks, "host_tick": session.host_tick, "session": session.session_id.left(8),
		"remote_motion": _remote_motion, "snapshots": session.snapshot_count,
		"corrections": session.prediction.corrections, "hard_snaps": session.prediction.hard_snaps,
		"maximum_error": session.prediction.maximum_error, "history": session.prediction.commands.size(),
		"rtt_ticks": session.rtt_ticks, "measured_rtt_ms": session.measured_rtt_ms, "events": event_counts, "status": session.status,
		"rejected_commands": session.queue.rejected, "connected": session.transport.connected,
		"wire_rejected": session.transport.rejected, "wire_error": session.transport.error,
		"packet_counts": session.packet_counts, "service_tick": session.service_tick,
		"last_packet": session.last_packet_tick, "timeout_ticks": session.config.timeout_ticks,
		"maximum_physics_gap_ms": _maximum_physics_gap_usec / 1000.0}
	report.merge({"round": session.round_id, "phase": session.phase(), "winner": session.winner,
		"round_complete": session.round_complete,
		"input_ack": session.last_simulated_sequence,
		"retry_started": session.round_id == 2 and (session.barrier.gate.released if session.host else session.phase() == RaceBaseline.Phase.RUNNING),
		"progress": session.progress, "deaths": session.deaths, "claims_sent": race_fixture.claims_sent,
		"authority_rejections": session.scope_rejections, "pool_peak": course.pool_high_water,
		"projectile_hits": course.projectile_hits, "pool_active": course.world.active_count(),
		"pool_nodes": course.world.projectiles.size(), "event_duplicates": session.events.duplicates,
		"fixture_steps": race_fixture.fixture_steps})
	var emulator: NetworkEmulator = session.transport as NetworkEmulator
	var buffer: SnapshotBuffer = session._host_remote_buffer if session.host else session.interpolation
	var stress_report: Dictionary = {"schema": NetworkTelemetry.SCHEMA, "build": BuildInfo.VERSION,
		"build_number": BuildInfo.BUILD_NUMBER, "protocol": BuildInfo.NETWORK_PROTOCOL_VERSION,
		"wire": BuildInfo.NETWORK_WIRE_REVISION, "map": course.definition.map_id,
		"map_checksum": course.definition.declared_checksum, "role": report.role,
		"physics_hz": 60, "snapshot_hz": session.config.snapshot_hz,
		"profile_changes": profile_changes, "viewport": [get_viewport().size.x, get_viewport().size.y], "emulator": emulator.report(), "telemetry": session.telemetry.report(),
		"prediction": {"ordinary_error_px": session.prediction.metrics.metric("ordinary_error_px"),
			"moving_error_px": session.prediction.metrics.metric("moving_error_px"),
			"overflow_rebases": session.prediction.overflow_rebases,
			"ordinary_corrections": session.prediction.ordinary_corrections,
			"ordinary_correction_rate_hz": session.prediction.ordinary_corrections * 60.0 / maxi(1, session.service_tick),
			"ordinary_hard_snaps": session.prediction.ordinary_hard_snaps,
			"lifecycle_rebases": session.prediction.lifecycle_rebases,
			"injected_corrections": session.prediction.injected_corrections,
			"rewinds": session.prediction.reconciliations, "replayed_commands": session.prediction.replayed_commands,
			"ack_lag_commands": session.prediction.metrics.metric("ack_lag_commands"),
			"history_high_water": session.prediction.history_high_water},
		"interpolation": {"underflow": buffer.underflow, "extrapolation": buffer.extrapolated,
			"hold": buffer.held, "interpolated": buffer.interpolated, "high_water": buffer.high_water},
		"functional": report.duplicate(true)}
	session.shutdown()
	stress_report["cleanup"] = {"queue": emulator.pending.size(), "history": session.prediction.commands.size(),
		"interpolation": session.remote_buffer_depth(), "pool_active": course.world.active_count(),
		"events": session.events.recent.size(), "ping_history": session._ping_times.size()}
	var report_path: String = option("report")
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		if file == null:
			success = false
		else:
			file.store_string(JSON.stringify(stress_report, "\t"))
	print("M15_RESULT=", JSON.stringify(report))
	print("PROJECTVELOCITY_M15_PROCESS_OK" if success else "M15_PROCESS_FAILED")
	get_tree().quit(0 if success else 1)
