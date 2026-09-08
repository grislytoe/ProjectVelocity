extends SceneTree
## Real physics contacts; isolated scene, no save storage.

var checks: int = 0
var failures: int = 0
var world: Node2D
var player: PlayerController
var observer: Observer
var frame := InputFrame.new()
var trace: String = ""

class Observer extends Node:
	signal stepped
	func _physics_process(_delta: float) -> void:
		stepped.emit()


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)


func ticks(count: int) -> void:
	for index: int in count:
		await observer.stepped
		trace += "%.4f,%.4f;" % [player.position.x, player.position.y]


func place(location: Vector2) -> void:
	frame = InputFrame.new()
	player.respawn_at(location)
	await ticks(2)


func run() -> void:
	var config := MovingPlatformConfig.new()
	config.route = PackedVector2Array([Vector2.ZERO, Vector2(60, 0), Vector2(60, -60)])
	config.speed = 60
	config.waits = PackedFloat32Array([0.5, 0, 0.5])
	var route := PlatformRoute.new(config)
	check(route.sample(29) == Vector2.ZERO, "Point wait uses fixed ticks")
	check(route.sample(60) == Vector2(30, 0), "Speed along first segment")
	check(route.sample(150) == Vector2(60, -60), "Arrival at third point")
	check(route.sample(route.total_ticks) == Vector2.ZERO, "Ping-pong loops exactly")
	config.reverse = true
	config.loop = false
	route = PlatformRoute.new(config)
	check(route.sample(0) == Vector2(60, -60), "Reverse starts at last point")
	check(route.sample(100000) == Vector2.ZERO, "Non-loop route stops at endpoint")
	config.loop = true
	config.ping_pong = false
	route = PlatformRoute.new(config)
	check(route.sample(route.total_ticks) == route.sample(0), "Closed loop wraps")
	config.speed = NAN
	check(not config.validate(), "Reject nonfinite speed")
	config.speed = 60
	config.waits = PackedFloat32Array([1])
	check(not config.validate(), "Reject mismatched waits")
	var pad_config := JumpPadConfig.new()
	pad_config.direction = Vector2.ZERO
	check(not pad_config.validate(), "Reject zero launch direction")
	var motor := PlayerMotor.new(PlayerMovementConfig.new())
	motor.start_dash(Vector2.DOWN)
	motor.launch(Vector2.UP * 1200)
	check(motor.events & PlayerMotor.Event.DASH_STARTED and motor.events & PlayerMotor.Event.DASH_ENDED,
		"Same-tick pad impact preserves Dash signals and selection clearing")
	world = Node2D.new()
	root.add_child(world)
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.position = Vector2(2000, -500)
	world.add_child(player)
	player.input_provider = func() -> InputFrame: return frame
	observer = Observer.new()
	observer.process_physics_priority = 200
	root.add_child(observer)
	var one := preload("res://gameplay/platforms/one_way_platform.tscn").instantiate() as StaticPlatform
	world.add_child(one)
	await place(Vector2(0, 95))
	player.motor.launch(Vector2(0, -800))
	frame.jump_held = true
	var crossed: bool = false
	for index: int in 90:
		await ticks(1)
		crossed = crossed or player.position.y < -65
	check(crossed and player.contacts.grounded, "One-way passes upward then lands")
	check(absf(player.position.y + 32) < 1, "One-way top contact height")
	check(RespawnSafety.valid(player, Vector2(0, -34)), "Permanent one-way can support safe spawn")
	one.free()
	var moving := preload("res://gameplay/platforms/moving_platform.tscn").instantiate() as MovingPlatform
	moving.config = MovingPlatformConfig.new()
	moving.config.speed = 60
	moving.config.waits = PackedFloat32Array([0, 0])
	world.add_child(moving)
	await place(Vector2(0, -34))
	await ticks(20)
	var relative: Vector2 = player.position - moving.position
	await ticks(60)
	check(player.contacts.grounded and absf((player.position - moving.position).x - relative.x) < 3,
		"Animatable platform carries idle controller horizontally")
	check(not RespawnSafety.valid(player, moving.position + Vector2(0, -34)), "Moving support rejected")
	frame.jump_pressed = true
	frame.jump_held = true
	await ticks(1)
	frame.jump_pressed = false
	check(player.velocity.y < -600, "Jump leaves moving platform")
	moving.free()
	moving = preload("res://gameplay/platforms/moving_platform.tscn").instantiate() as MovingPlatform
	moving.config = MovingPlatformConfig.new()
	moving.config.route = PackedVector2Array([Vector2.ZERO, Vector2(0, -200)])
	moving.config.waits = PackedFloat32Array([0.5, 0.5])
	moving.config.speed = 60
	world.add_child(moving)
	await place(Vector2(0, -34))
	await ticks(100)
	check(player.contacts.grounded and absf(player.position.y - moving.position.y + 32) < 3,
		"Vertical elevator carries controller")
	moving.free()
	var fragile := preload("res://gameplay/platforms/breakable_platform.tscn").instantiate() as BreakablePlatform
	fragile.config = BreakablePlatformConfig.new()
	fragile.config.activation_delay = 0.1
	fragile.config.restore_delay = 0.1
	world.add_child(fragile)
	await place(Vector2(0, -34))
	await ticks(3)
	check(fragile.state == BreakablePlatform.State.ARMED, "Standing contact arms temporary surface")
	check(not RespawnSafety.valid(player, Vector2(0, -34)), "Temporary support rejects checkpoint")
	await ticks(7)
	check(fragile.surface.disabled, "Activation delay removes collision")
	player.simulation_enabled = false
	player.position = Vector2.ZERO
	await ticks(12)
	check(fragile.surface.disabled, "Restoration cannot embed occupant")
	player.position = Vector2(500, 0)
	await ticks(3)
	check(fragile.state == BreakablePlatform.State.SOLID and not fragile.surface.disabled, "Clear platform restores")
	player.simulation_enabled = true
	fragile.config = fragile.config.duplicate() as BreakablePlatformConfig
	fragile.config.restores = false
	await place(Vector2(0, -34))
	await ticks(30)
	check(fragile.state == BreakablePlatform.State.ABSENT, "Optional permanent disappearance")
	fragile.free()
	var pad := preload("res://gameplay/platforms/jump_pad.tscn").instantiate() as JumpPad
	pad.config = JumpPadConfig.new()
	pad.config.direction = Vector2(1, -1)
	pad.config.force = 1200
	world.add_child(pad)
	await place(Vector2(0, -100))
	frame.dash_pressed = true
	frame.dash_direction = Vector2.DOWN
	await ticks(1)
	frame.dash_pressed = false
	var launched: bool = false
	for index: int in 10:
		await ticks(1)
		if player.velocity.y < -800:
			launched = true
			break
	check(launched and player.velocity.is_equal_approx(Vector2(1, -1).normalized() * 1200),
		"Real Dash impact replaced by configured diagonal pad force")
	check(player.motor.dash_ticks == 0 and player.motor.machine.current != PlayerStateMachine.State.DASH,
		"Pad ends Dash state without stale timer")
	check(not RespawnSafety.valid(player, Vector2(0, -34)), "Jump pad rejects automatic respawn launch")
	player.die(true)
	pad.on_player_contact(player, Vector2.UP)
	check(player.velocity == Vector2.ZERO, "Dead actor cannot launch")
	await place(Vector2(500, -100))
	player.start_blocked = true
	var blocked_velocity: Vector2 = player.velocity
	pad.on_player_contact(player, Vector2.UP)
	check(player.velocity == blocked_velocity, "Start barrier rejects launch")
	player.start_blocked = false
	player.finish_run()
	pad.on_player_contact(player, Vector2.UP)
	check(player.velocity == Vector2.ZERO, "Finished actor cannot launch")
	world.free()
	var arena := preload("res://dev_tools/test_playground.tscn").instantiate() as TestPlayground
	root.add_child(arena)
	player = arena.player
	player.input_provider = func() -> InputFrame: return frame
	for index: int in range(12, 16):
		arena.request_station(index)
		await ticks(2)
		var module := arena.geometry.get_node("Module") as Node2D
		await place(module.position + Vector2(0, -34))
		await ticks(3)
		match index:
			12: check(player.contacts.grounded, "Playground one-way landing")
			13: check(player.contacts.grounded, "Playground moving support contact")
			14: check((module as BreakablePlatform).state == BreakablePlatform.State.ARMED,
				"Playground temporary platform arms")
			15: check(player.velocity.y < -500, "Playground pad launches")
	arena.free()
	print("M8_REPLAY_HASH=" + trace.sha256_text())
	print("PROJECTVELOCITY_M8_OK checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)
