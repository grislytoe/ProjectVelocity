extends Node
## M24 developer benchmark: real Foundry composition, two presentations and bounded pools.

const Stats = preload("res://dev_tools/performance/benchmark_stats.gd")
const Profile = preload("res://dev_tools/performance/benchmark_profile.gd")
const SEED: int = 240024
var profile := Profile.new()
var scenario: String = "hazard_station"
var output_path: String = "res://builds/validation/m24/result.json"
var warmup_frames: int = 120
var sample_frames: int = 600
var frame_ms: Array[float] = []
var process_ms: Array[float] = []
var physics_ms: Array[float] = []
var draw_calls: Array[float] = []
var primitives: Array[float] = []
var runtime: SettingsRuntime
var course: NetworkCourse
var solo_course: SoloCourse
var layer: InputLayer
var first_use: Dictionary = {}
var leak: Dictionary = {}
var baseline_objects: Dictionary = {}
var route_complete: bool = false
var pool_peak: int = 0
var engagement_peak: int = 0


class RouteDriver extends Node:
	var player: PlayerController
	var commands: Array[Vector3] = []
	var cursor: int = 0
	var held: int = 0
	func configure(actor: PlayerController) -> void:
		player = actor
		var routes: Array = [
			[Vector3(840,1,0),Vector3(1800,1,0),Vector3(2910,4,0),Vector3(4070,1,0)],
			[Vector3(1680,1,0),Vector3(2030,1,0),Vector3(2270,1,0),Vector3(2740,1,0),Vector3(3700,1,0),Vector3(4340,1,0)],
			[Vector3(900,1,0),Vector3(2320,1,0),Vector3(2480,2,40),Vector3(2480,2,0),Vector3(2480,2,0),Vector3(2480,2,0),Vector3(4090,1,0)],
			[Vector3(900,1,0),Vector3(2270,1,0),Vector3(2510,2,0),Vector3(2780,3,0),Vector3(4000,1,0),Vector3(4600,1,0)],
			[Vector3(1870,1,0),Vector3(2140,2,0),Vector3(2740,1,0),Vector3(2940,2,0),Vector3(3740,1,0),Vector3(3930,2,0),Vector3(4440,1,0)],
			[Vector3(1620,5,0),Vector3(1920,2,0),Vector3(2120,1,0),Vector3(2800,1,0),Vector3(3300,2,0),Vector3(4140,1,0)],
			[Vector3(850,1,0),Vector3(2000,1,0),Vector3(2820,1,0),Vector3(3720,1,0),Vector3(3900,2,0),Vector3(4340,1,0)],
			[Vector3(800,1,0),Vector3(1960,1,0),Vector3(2220,1,0),Vector3(3100,1,0),Vector3(3870,1,0)],
		]
		for section: int in routes.size():
			for command: Vector3 in routes[section]:
				commands.append(command + Vector3(section * 5200, 0, 0))
		player.input_provider = input
	func input() -> InputFrame:
		var frame := InputFrame.new()
		if player == null or player.motor.machine.locked(): return frame
		frame.movement = Vector2.RIGHT
		if cursor < commands.size() and player.position.x >= commands[cursor].x:
			if int(commands[cursor].y) == 1 and not player.contacts.grounded:
				frame.movement = Vector2.ZERO
			elif commands[cursor].z > 0:
				commands[cursor].z -= 1
			else:
				var action: int = int(commands[cursor].y)
				frame.jump_pressed = action in [1, 2, 4]
				frame.dash_pressed = action in [3, 6, 7]
				frame.dash_direction = Vector2(1, -1).normalized() if action == 7 else (
					Vector2.UP if action == 6 else Vector2.RIGHT)
				if frame.dash_pressed: frame.movement = frame.dash_direction
				held = 4 if action == 4 else 100
				cursor += 1
		frame.jump_held = held > 0
		held = maxi(0, held - 1)
		return frame


func option(key: String, fallback: String) -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--" + key + "="):
			return argument.substr(key.length() + 3)
	return fallback


func _ready() -> void:
	run.call_deferred()


func _physics_process(_delta: float) -> void:
	if course != null and course.world != null:
		pool_peak = maxi(pool_peak, course.world.active_count())
		for id: StringName in [&"local", &"absent"]:
			if course.world.engagements.has(id):
				engagement_peak = maxi(engagement_peak, course.world.engagements[id].size())


func run() -> void:
	if not OS.is_debug_build():
		push_error("M24 benchmark is development-only")
		get_tree().quit(1)
		return
	scenario = option("scenario", scenario)
	profile.preset = option("preset", "balanced")
	var dimensions: PackedStringArray = option("resolution", "1280x800").split("x")
	if dimensions.size() == 2:
		profile.resolution = Vector2i(int(dimensions[0]), int(dimensions[1]))
	profile.paced = option("paced", "true") == "true"
	profile.vsync = option("vsync", "true") == "true"
	profile.fps_limit = 60 if profile.paced else 0
	warmup_frames = int(option("warmup", "120"))
	sample_frames = int(option("samples", "600"))
	output_path = option("output", output_path)
	if not profile.valid() or scenario not in ["solo_traversal", "hazard_station", "ui_first_open", "load_leak"] \
		or warmup_frames < 1 or sample_frames < 30:
		push_error("Invalid M24 benchmark arguments")
		get_tree().quit(2)
		return
	seed(SEED)
	baseline_objects = object_monitors()
	layer = InputLayer.new()
	layer.watch_hardware = false
	add_child(layer)
	runtime = SettingsRuntime.new()
	add_child(runtime)
	runtime.apply(profile.settings())
	DisplayServer.window_set_size(profile.resolution)
	match scenario:
		"ui_first_open": await setup_ui()
		"load_leak": await setup_load_leak()
		_: await setup_course()
	for _frame: int in warmup_frames:
		await get_tree().process_frame
	for _frame: int in sample_frames:
		var started: int = Time.get_ticks_usec()
		await get_tree().process_frame
		frame_ms.append((Time.get_ticks_usec() - started) / 1000.0)
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	await finish()


func setup_course() -> void:
	if scenario == "solo_traversal":
		await setup_solo_traversal()
		return
	var started: int = Time.get_ticks_usec()
	course = NetworkCourse.new()
	course.definition = MapCatalog.industrial()
	course.host = true
	runtime.world.viewport.add_child(course)
	first_use.course_construction_ms = elapsed_ms(started)
	for actor: PlayerController in course.actors:
		actor.start_blocked = false
		actor.simulation_enabled = false
	started = Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	first_use.generated_background_first_draw_ms = elapsed_ms(started)
	setup_hazard_station()


func setup_solo_traversal() -> void:
	var started: int = Time.get_ticks_usec()
	solo_course = SoloCourse.new()
	solo_course.definition = MapCatalog.industrial()
	solo_course.input_layer = layer
	runtime.world.viewport.add_child(solo_course)
	first_use.course_construction_ms = elapsed_ms(started)
	solo_course.player.start_blocked = false
	var driver := RouteDriver.new()
	add_child(driver)
	driver.configure(solo_course.player)
	solo_course.lifecycle.completed.connect(func() -> void: route_complete = true)
	# A presentation-only opponent exercises the M23 30% treatment without a second authority.
	var opponent := preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	opponent.collision_layer = 0
	opponent.collision_mask = 0
	opponent.simulation_enabled = false
	opponent.position = solo_course.player.position + Vector2(60, 0)
	solo_course.add_child(opponent)
	opponent.presentation.is_local = false
	started = Time.get_ticks_usec()
	await RenderingServer.frame_post_draw
	first_use.generated_background_first_draw_ms = elapsed_ms(started)
	var frame := PlayerVisualFrame.new()
	frame.state = PlayerStateMachine.State.RUN
	frame.velocity = Vector2(700, 0)
	frame.speed_ratio = 1.0
	started = Time.get_ticks_usec()
	opponent.presentation.present(frame)
	first_use.first_animation_ms = elapsed_ms(started)


func setup_hazard_station() -> void:
	var station := Vector2(7 * 5200 + 3880, 390)
	for index: int in 2:
		course.actors[index].position = station + Vector2(350, index * 80)
	# Three real dual-channel turrets exercise the approved three-engagement cap per target.
	for index: int in 3:
		var turret := Turret.new()
		turret.config = preload("res://gameplay/hazards/default_turret.tres")
		turret.position = station + Vector2(-420, (index - 1) * 120)
		turret.bind(course.world, [&"local", &"absent"])
		course.add_child(turret)
	var config: TurretConfig = preload("res://gameplay/hazards/default_turret.tres")
	var started: int = Time.get_ticks_usec()
	for index: int in 10:
		var target: StringName = &"local" if index < 5 else &"absent"
		course.world.fire(target, station + Vector2(-1000, -500 - index * 12), Vector2.LEFT,
			config, 2400 + index)
	pool_peak = course.world.active_count()
	first_use.first_projectile_and_pool_warm_ms = elapsed_ms(started)
	var ids: Array[int] = []
	for projectile: HazardProjectile in course.world.projectiles:
		ids.append(projectile.get_instance_id())
	set_meta("pool_ids", ids)
	# Explicit over-cap shot must skip instead of allocate or defer.
	course.world.fire(&"local", station, Vector2.RIGHT, config, 9999)


func setup_ui() -> void:
	var folder: String = OS.get_cache_dir().path_join("pv-m24-ui-" + PlayerProfileData.new_uuid())
	set_meta("ui_folder", folder)
	var store := SaveStore.new(folder)
	store.open()
	store.data.onboarding_complete = true
	var ui := AppUI.new()
	ui.store = store
	ui.input_layer = layer
	var started: int = Time.get_ticks_usec()
	add_child(ui)
	await get_tree().process_frame
	first_use.menu_ms = elapsed_ms(started)
	started = Time.get_ticks_usec()
	ui.show_online()
	await get_tree().process_frame
	first_use.lobby_ms = elapsed_ms(started)
	var session := NetworkSession.new()
	session.host = true
	session.series.configure(MapCatalog.training(), 1)
	session.series.phase = OnlineSeries.Phase.FINAL_SERIES_RESULTS
	var overlay := OnlineMatchOverlay.new()
	add_child(overlay)
	overlay.bind(session, layer)
	started = Time.get_ticks_usec()
	overlay.refresh()
	await get_tree().process_frame
	first_use.results_ms = elapsed_ms(started)
	set_meta("ui_nodes", [ui, overlay, session])


func setup_load_leak() -> void:
	var started: int = Time.get_ticks_usec()
	var cold := SoloCourse.new()
	cold.definition = MapCatalog.industrial()
	cold.input_layer = layer
	runtime.world.viewport.add_child(cold)
	await get_tree().process_frame
	first_use.coldish_course_ms = elapsed_ms(started)
	cold.free()
	await get_tree().process_frame
	# Resource growth in the first cycle is engine cache. Measure ten steady-state cycles after it.
	var before: Dictionary = object_monitors()
	var static_before: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	var peak_construct: float = 0.0
	for _cycle: int in 10:
		started = Time.get_ticks_usec()
		var item := SoloCourse.new()
		item.definition = MapCatalog.industrial()
		item.input_layer = layer
		runtime.world.viewport.add_child(item)
		await get_tree().process_frame
		var duration: float = elapsed_ms(started)
		peak_construct = maxf(peak_construct, duration)
		item.free()
		await get_tree().process_frame
	leak = {
		"cycles": 10,
		"node_delta": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - int(before.nodes),
		"resource_delta": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)) - int(before.resources),
		"orphan_delta": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) - int(before.orphans),
		"static_memory_delta_bytes": maxf(0.0, Performance.get_monitor(Performance.MEMORY_STATIC) - static_before),
		"warm_construct_max_ms": peak_construct,
	}


func finish() -> void:
	var frame_summary: Dictionary = Stats.summarize(frame_ms)
	var objects: Dictionary = object_monitors()
	var pool_data: Dictionary = {"capacity": 0, "active": 0, "skipped": 0,
		"stable_instance_ids": 0, "per_target_cap": 0}
	if course != null:
		var current_ids: Array[int] = []
		for projectile: HazardProjectile in course.world.projectiles:
			current_ids.append(projectile.get_instance_id())
		pool_data = {"capacity": course.world.projectiles.size(), "active_final": course.world.active_count(),
			"active_peak": pool_peak,
			"skipped": course.world.skipped_shots,
			"stable_instance_ids": 1 if not has_meta("pool_ids") or get_meta("pool_ids") == current_ids else 0,
			"per_target_cap": course.world.caps.projectiles_per_target,
			"engaging_per_target_cap": course.world.caps.engaging_turrets_per_target,
			"engaging_peak_per_target": engagement_peak}
	elif solo_course != null:
		pool_data = {"capacity": solo_course.world.projectiles.size(), "active": solo_course.world.active_count(),
			"skipped": solo_course.world.skipped_shots, "stable_instance_ids": 1,
			"per_target_cap": solo_course.world.caps.projectiles_per_target,
			"route_complete": 1 if route_complete else 0}
	if leak.is_empty():
		leak = {"cycles": 0, "node_delta": 0, "resource_delta": 0, "orphan_delta": 0,
			"static_memory_delta_bytes": 0.0}
	var result := {
		"schema": Stats.SCHEMA,
		"scenario": scenario,
		"identity": {"engine": Engine.get_version_info().string, "game_version": BuildInfo.VERSION,
			"build_number": BuildInfo.BUILD_NUMBER, "git_sha": option("git-sha", "unknown"),
			"renderer": RenderingServer.get_current_rendering_method(),
			"rendering_driver": RenderingServer.get_current_rendering_driver_name()},
		"environment": {"os": OS.get_name() + " " + OS.get_version(),
			"cpu": OS.get_processor_name(), "logical_processors": OS.get_processor_count(),
			"gpu": RenderingServer.get_video_adapter_name(),
			"hardware_class": option("hardware-class", "actual-not-certified"),
			"power_state": option("power-state", "not-reported")},
		"configuration": {"preset": profile.preset, "resolution": [profile.resolution.x, profile.resolution.y],
			"world_resolution": [profile.world_resolution().x, profile.world_resolution().y],
			"paced": profile.paced, "vsync": profile.vsync if profile.paced else false,
			"fps_limit": profile.fps_limit if profile.paced else 0, "physics_hz": Engine.physics_ticks_per_second,
			"snapshot_hz": Stats.unavailable("not a network-process scenario")},
		"sampling": {"warmup_frames": warmup_frames, "sample_frames": sample_frames, "seed": SEED},
		"timing": {"frame_ms": frame_summary, "process_ms": Stats.summarize(process_ms),
			"physics_ms": Stats.summarize(physics_ms),
			"fps_monitor": Performance.get_monitor(Performance.TIME_FPS)},
		"render": {"draw_calls": Stats.summarize_counter(draw_calls),
			"primitives": Stats.summarize_counter(primitives),
			"video_memory_bytes": monitor_or_unavailable(Performance.RENDER_VIDEO_MEM_USED, "Compatibility backend did not expose GPU memory"),
			"texture_memory_bytes": monitor_or_unavailable(Performance.RENDER_TEXTURE_MEM_USED, "Compatibility backend did not expose texture memory")},
		"objects": objects,
		"memory": {"static_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
			"static_peak_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
			"decoded_texture_budget_bytes": 2097152,
			"process_working_set_bytes": Stats.unavailable("populated by external launcher sampler"),
			"process_private_bytes": Stats.unavailable("populated by external launcher sampler")},
		"pools": pool_data,
		"leak": leak,
		"first_use": first_use if not first_use.is_empty() else {"available": false, "reason": "not exercised"},
		"acceptance": Stats.classify(frame_summary, option("certified-hardware", "false") == "true"),
	}
	var errors: PackedStringArray = Stats.validate_result(result)
	if not errors.is_empty():
		push_error("M24 result schema failed: " + ", ".join(errors))
		get_tree().quit(3)
		return
	DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	var summary_path: String = output_path.get_basename() + ".txt"
	file = FileAccess.open(summary_path, FileAccess.WRITE)
	file.store_string("M24 %s %s %dx%d\nframe p50 %.3f p95 %.3f p99 %.3f max %.3f ms\nstatus %s: %s\n" % [
		scenario, profile.preset, profile.resolution.x, profile.resolution.y,
		frame_summary.p50_ms, frame_summary.p95_ms, frame_summary.p99_ms, frame_summary.max_ms,
		result.acceptance.status, result.acceptance.reason])
	file.close()
	file = FileAccess.open(output_path.get_basename() + ".csv", FileAccess.WRITE)
	file.store_string("scenario,preset,width,height,paced,p50_ms,p95_ms,p99_ms,max_ms,over_16_667,over_25,over_33_333,status\n")
	file.store_csv_line(PackedStringArray([scenario, profile.preset, str(profile.resolution.x), str(profile.resolution.y),
		str(profile.paced), str(frame_summary.p50_ms), str(frame_summary.p95_ms), str(frame_summary.p99_ms),
		str(frame_summary.max_ms), str(frame_summary.over_16_667), str(frame_summary.over_25),
		str(frame_summary.over_33_333), result.acceptance.status]))
	file.close()
	print("PROJECTVELOCITY_M24_BENCHMARK_OK ", JSON.stringify(result.acceptance))
	cleanup()
	get_tree().quit(0)


func object_monitors() -> Dictionary:
	return {"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))}


func monitor_or_unavailable(monitor: Performance.Monitor, reason: String) -> Variant:
	var value: float = Performance.get_monitor(monitor)
	return value if value > 0.0 else Stats.unavailable(reason)


func elapsed_ms(started: int) -> float:
	return (Time.get_ticks_usec() - started) / 1000.0


func cleanup() -> void:
	if has_meta("ui_nodes"):
		for node: Node in get_meta("ui_nodes"):
			if not is_instance_valid(node): continue
			if node is NetworkSession and is_instance_valid(node.barrier):
				node.barrier.free()
			node.free()
	if course != null and is_instance_valid(course): course.free()
	if solo_course != null and is_instance_valid(solo_course): solo_course.free()
	if has_meta("ui_folder"):
		var folder: String = get_meta("ui_folder")
		for filename: String in DirAccess.get_files_at(folder):
			DirAccess.remove_absolute(folder.path_join(filename))
		DirAccess.remove_absolute(folder)
