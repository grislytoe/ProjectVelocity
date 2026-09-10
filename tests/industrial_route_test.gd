extends SceneTree
## Real SoloTrial and PlayerController. Route input never relocates or alters the motor.

var trial: SoloTrial
var driver: Driver
var store: SaveStore
var folder: String
var failures: int = 0

class EarlyProbe extends Node:
	var started_usec: int = 0
	func _physics_process(_delta: float) -> void:
		started_usec = Time.get_ticks_usec()

class Driver extends Node:
	var trial: SoloTrial
	var commands: Array[Vector3] = [] # world X, action (jump/double/dash/short), delay ticks
	var cursor: int = 0
	var held: int = 0
	var frames: Array = []
	var events: int = 0
	var max_pool: int = 0
	var wall_slide_ticks: int = 0
	var last_second: int = -1
	var surfaces: Dictionary = {}
	var used_express_perch: bool = false
	var shortcut: bool = false
	var recovery: bool = false
	var recovery_section: int = 0
	var recovery_tick: int = -1
	var losses: Array[int] = []
	var original_commands: Array[Vector3] = []
	var physics_ms: Array[float] = []
	var probe := EarlyProbe.new()
	func _ready() -> void:
		process_physics_priority = 200
		probe.process_physics_priority = -200
		add_child(probe)
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
		if shortcut:
			routes[2] = [Vector3(900,1,0),Vector3(1700,1,0),Vector3(1880,2,0),
				Vector3(1960,1,0),Vector3(2310,7,0),Vector3(4090,1,0)]
		for section: int in routes.size():
			for command: Vector3 in routes[section]:
				commands.append(command + Vector3(section * 5200, 0, 0))
		original_commands = commands.duplicate()
		trial.course.player.input_provider = input
	func input() -> InputFrame:
		var frame := InputFrame.new()
		if trial.phase != SoloTrial.Phase.RUN:
			return frame
		var player: PlayerController = trial.course.player
		if player.motor.machine.locked():
			return frame
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
				if frame.dash_pressed:
					frame.movement = frame.dash_direction
				held = 4 if action == 4 else 100
				print("INPUT %d x=%.1f y=%.1f action=%d floor=%s" % [trial.elapsed,player.position.x,player.position.y,action,player.contacts.grounded])
				cursor += 1
		frame.jump_held = held > 0
		held = maxi(0, held - 1)
		frames.append([frame.movement.x,frame.jump_pressed,frame.jump_held,frame.dash_pressed,frame.dash_direction.y])
		return frame
	func _physics_process(_delta: float) -> void:
		if trial.course == null:
			return
		var player: PlayerController = trial.course.player
		if trial.phase == SoloTrial.Phase.RUN:
			physics_ms.append((Time.get_ticks_usec() - probe.started_usec) / 1000.0)
		if recovery and recovery_section < 8 and trial.phase == SoloTrial.Phase.RUN:
			var destination: float = recovery_section * 5200 + 4900
			if player.position.x >= destination:
				if recovery_tick < 0:
					recovery_tick = trial.elapsed
					player.die()
					commands = original_commands.duplicate()
					cursor = 0
					while cursor < commands.size() and commands[cursor].x < recovery_section * 5200 + 180:
						cursor += 1
				else:
					if not player.motor.machine.locked():
						losses.append(trial.elapsed - recovery_tick)
						print("RECOVERY section=%d ticks=%d" % [recovery_section + 1, losses.back()])
						recovery_section += 1
						recovery_tick = -1
		events |= player.motor.events
		for index: int in player.get_slide_collision_count():
			var body: Object = player.get_slide_collision(index).get_collider()
			if body is Node and body.name == &"ExpressPerch":
				used_express_perch = true
			if body is MovingPlatform:
				surfaces.moving = true
			if body is BreakablePlatform:
				surfaces.breakable = true
			if body is JumpPad:
				surfaces.pad = true
			if body is StaticPlatform and body.config.one_way:
				surfaces.one_way = true
		max_pool = maxi(max_pool, trial.course.world.active_count())
		if player.motor.machine.current == PlayerStateMachine.State.WALL_SLIDE:
			wall_slide_ticks += 1
		if trial.elapsed / 60 != last_second:
			last_second = trial.elapsed / 60
			print("POS %d %.1f %.1f cursor=%d" % [trial.elapsed,player.position.x,player.position.y,cursor])

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	Engine.max_fps = 0
	var initial_nodes: int = get_node_count()
	folder = OS.get_cache_dir().path_join("pv-m14-" + PlayerProfileData.new_uuid())
	store = SaveStore.new(folder)
	store.open()
	var layer := InputLayer.new()
	layer.watch_hardware = false
	root.add_child(layer)
	var world := WorldPresentation.new()
	root.add_child(world)
	world.apply({"resolution": [1280,800], "effects_quality": "balanced"})
	trial = SoloTrial.new()
	trial.layer = layer
	trial.records = TrialRecords.new(store, MapCatalog.industrial())
	world.viewport.add_child(trial)
	await physics_frame
	await physics_frame
	if trial.phase == SoloTrial.Phase.ERROR:
		quit(1)
		return
	driver = Driver.new()
	driver.trial = trial
	driver.shortcut = "--shortcut" in OS.get_cmdline_user_args()
	driver.recovery = "--recovery" in OS.get_cmdline_user_args()
	root.add_child(driver)
	trial.dismiss_hint()
	var captures: Array[int] = [260,680,1210,1840,2280,2720,3320,3700]
	var capture_index: int = 0
	while trial.elapsed < 12000 and trial.phase != SoloTrial.Phase.RESULT and (driver.recovery or trial.deaths == 0):
		await physics_frame
		if "--capture" in OS.get_cmdline_user_args() and capture_index < captures.size() \
			and trial.elapsed >= captures[capture_index]:
			await RenderingServer.frame_post_draw
			world.viewport.get_texture().get_image().save_png("res://builds/m14/section-%d.png" % (capture_index + 1))
			capture_index += 1
	print("M14_RESULT ticks=%d splits=%s deaths=%d phase=%d events=%d slide=%d pool=%d" % [
		trial.elapsed,trial.splits,trial.deaths,trial.phase,driver.events,driver.wall_slide_ticks,driver.max_pool])
	var expected_deaths: int = 8 if driver.recovery else 0
	var ok: bool = trial.phase == SoloTrial.Phase.RESULT and trial.deaths == expected_deaths and trial.result.saved
	ok = ok and trial.course.world.active_count() == 0 and driver.max_pool <= 5
	print("M14_CONTACTS " + str(driver.surfaces))
	ok = ok and driver.surfaces.size() == 4
	ok = ok and driver.used_express_perch == driver.shortcut
	if not driver.shortcut:
		ok = ok and driver.events == 63 and driver.wall_slide_ticks > 0
	if driver.recovery:
		ok = ok and driver.losses.size() == 8
		for loss: int in driver.losses:
			ok = ok and loss >= 300 and loss <= 900
	else:
		ok = ok and trial.elapsed >= 3600 and trial.elapsed <= 7200
	var evidence := {"ticks": trial.elapsed, "splits": trial.splits, "deaths": trial.deaths,
		"events": driver.events, "wall_slide_ticks": driver.wall_slide_ticks,
		"contacts": driver.surfaces, "max_projectiles": driver.max_pool, "loss_ticks": driver.losses,
		"express_perch": driver.used_express_perch,
		"input_sha256": JSON.stringify(driver.frames).sha256_text(), "checksum": trial.records.checksum}
	driver.physics_ms.sort()
	if not driver.physics_ms.is_empty():
		evidence.physics_p95_ms = driver.physics_ms[int(driver.physics_ms.size() * 0.95)]
		evidence.physics_max_ms = driver.physics_ms.back()
	print("M14_REPLAY_HASH=" + str(evidence.input_sha256))
	var suffix: String = "recovery" if driver.recovery else ("shortcut" if driver.shortcut else "main")
	var evidence_file := FileAccess.open("res://builds/m14/" + suffix + "-evidence.json", FileAccess.WRITE)
	evidence_file.store_string(JSON.stringify(evidence, "\t"))
	evidence_file.close()
	var file := FileAccess.open("res://builds/m14/replay.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(driver.frames))
	file.close()
	driver.free()
	trial.free()
	world.free()
	layer.free()
	ok = ok and get_node_count() == initial_nodes
	for name: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	if ok:
		print("PROJECTVELOCITY_M14_ROUTE_OK")
	quit(0 if ok else 1)
