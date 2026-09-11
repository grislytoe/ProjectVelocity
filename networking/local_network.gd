extends Node
## Explicit development composition root. No SaveStore / TrialRecords and no persistent UUID on wire.

var session: NetworkSession
var course: NetworkCourse
var hud: Label
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
	emulator.configure(option("emulation", "clean"), int(option("seed", "15")))
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
	hud = Label.new()
	hud.position = Vector2(30, 25)
	hud.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hud)
	DisplayServer.window_set_title("ProjectVelocity M15 Local Network — " + role)
	print("M15_READY role=", role, " protocol=", config.protocol, " map=", course.definition.map_id)

func bot_input() -> InputFrame:
	var frame := InputFrame.new()
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
	if automated and not session.host and option("reconnect") == "true":
		if session.service_tick == 700:
			session.transport.close()
			session.disconnected()
		elif session.service_tick == 745:
			retry_connection()
	if automated and session.host and option("lifecycle") == "true":
		lifecycle_fixture()
	_clock_monotonic = _clock_monotonic and session.clock_ticks >= _previous_clock
	_previous_clock = session.clock_ticks
	_remote_motion += course.remote.position.distance_to(_previous_remote)
	_previous_remote = course.remote.position
	if automated and not session.host and session.clock_ticks > 120 and not injected:
		course.actors[1].position += Vector2(180, -40)
		injected = true
	var emulator: NetworkEmulator = session.transport as NetworkEmulator
	hud.text = ("M15 DEV • %s • player %d • session %s\n%s\n" % [
		"HOST" if session.host else "CLIENT", 1 if session.host else 2,
		session.session_id.left(8), session.status + countdown_text()]) + (
		"Host tick %d / client %d | match %.3fs | RTT %dms %s\n" % [
		session.host_tick, session.client_tick, session.clock_ticks / 60.0,
		session.rtt_ticks * 1000 / 60, "CONNECTION WARNING" if session.rtt_ticks >= 12 else ""]) + (
		"Sim loss %.0f%% • dropped %d • snapshot age %d • history %d\n" % [
		emulator.loss * 100, emulator.dropped, session.service_tick - session.last_snapshot_service,
		session.prediction.commands.size()]) + (
		"Corrections %d • error %.2fpx • hard %d • interpolation %d\n" % [
		session.prediction.corrections, session.prediction.last_error, session.prediction.hard_snaps,
		session.remote_buffer_depth()]) + "WASD / left stick • Space / A: Jump • Shift / RB: Dash\nF8: disconnect • F9: retry same session • close window to leave\nLocal developer session • no Time Trial records"
	if automated and DisplayServer.get_name() != "headless" and session.clock_ticks > 120 \
		and _screenshots < 2 and session.service_tick % 120 == 0 and not option("evidence").is_empty():
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

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or session == null:
		return
	if event.keycode == KEY_F8:
		session.transport.close()
		session.disconnected()
	elif event.keycode == KEY_F9 and not session.host and not session.joined:
		retry_connection()

func retry_connection() -> void:
	var emulator: NetworkEmulator = session.transport as NetworkEmulator
	var local: LocalENetTransport = emulator.inner as LocalENetTransport
	if local.open(false, _retry_port) == OK:
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
		"rtt_ticks": session.rtt_ticks, "events": event_counts, "status": session.status,
		"rejected_commands": session.queue.rejected, "connected": session.transport.connected,
		"wire_rejected": session.transport.rejected, "wire_error": session.transport.error,
		"packet_counts": session.packet_counts, "service_tick": session.service_tick,
		"last_packet": session.last_packet_tick}
	print("M15_RESULT=", JSON.stringify(report))
	session.shutdown()
	print("PROJECTVELOCITY_M15_PROCESS_OK" if success else "M15_PROCESS_FAILED")
	get_tree().quit(0 if success else 1)
