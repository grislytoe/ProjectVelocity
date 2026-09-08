extends SceneTree
## Runs the real M6 scene and its collision geometry. Never opens a profile/save path.

var arena: TestPlayground
var frame := InputFrame.new()
var checks: int = 0
var failures: int = 0
var observer: TickObserver


class TickObserver extends Node:
	signal stepped

	func _physics_process(_delta: float) -> void:
		stepped.emit()


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func ticks(count: int) -> void:
	for tick: int in count:
		await observer.stepped


func select(index: int) -> void:
	frame = InputFrame.new()
	arena.request_station(index)
	await ticks(2)


func run() -> void:
	arena = preload("res://dev_tools/test_playground.tscn").instantiate() as TestPlayground
	root.add_child(arena)
	observer = TickObserver.new()
	observer.process_physics_priority = 200
	root.add_child(observer)
	arena.player.input_provider = func() -> InputFrame: return frame
	check(arena.stations.size() == 22, "All twenty-two stations available; original sixteen retained")
	var exports := ConfigFile.new()
	check(exports.load("res://export_presets.cfg") == OK and
		"dev_tools/*" in String(exports.get_value("preset.0", "exclude_filter", "")),
		"Developer playground excluded from staging export")
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		for station: PlaygroundStation in arena.stations:
			var key: String = "M6_" + station.id
			check(tr(key) != key and tr(key + "_HINT") != key + "_HINT", "Station translations: " + locale + "/" + key)
	var ids: Dictionary = {}
	for index: int in arena.stations.size():
		var previous: Node2D = arena.geometry
		await select(index)
		check(not is_instance_valid(previous), "Old station freed before next physics step")
		var station: PlaygroundStation = arena.stations[index]
		check(not ids.has(station.id), "Unique station id")
		ids[station.id] = true
		check(station.envelope.has_point(station.spawn), "Spawn inside recovery envelope")
		check(arena.camera.map_bounds.rectangle == station.envelope, "Camera follows station bounds")
		check(arena.player.position.distance_to(station.spawn) < 8, "Safe independent spawn")
		check(arena.player.motor.dash_available and arena.player.motor.double_jump_available, "Teleport refills abilities")
		check(arena.player.motor.dash_ticks == 0 and arena.player.motor.wall_lock_ticks == 0, "Teleport clears temporary locks")
	await select(0)
	await ticks(20)
	frame.movement.x = 1
	await ticks(30)
	check(is_equal_approx(arena.player.velocity.x, 680), "Ground station reaches running speed")
	frame.movement.x = 0
	await ticks(15)
	check(is_zero_approx(arena.player.velocity.x), "Ground station supports braking")
	frame.movement.x = -1
	await ticks(30)
	check(arena.player.velocity.x < -670, "Ground reversal")
	await select(1)
	await ticks(20)
	frame.jump_pressed = true
	frame.jump_held = true
	frame.movement.x = 1
	await ticks(1)
	frame.jump_pressed = false
	await ticks(12)
	check(arena.player.velocity.x > 300 and not arena.player.contacts.grounded, "Air acceleration")
	frame.movement.x = -1
	await ticks(18)
	check(arena.player.velocity.x < 0, "Air reversal")
	var tap_rise: float = await jump_height(false)
	var held_rise: float = await jump_height(true)
	check(held_rise > tap_rise + 40, "Variable station distinguishes tap and held jump")
	await select(3)
	await ticks(20)
	frame.movement.x = 1
	var found_edge: bool = false
	for tick: int in 80:
		await ticks(1)
		if not arena.player.contacts.grounded and arena.player.motor.coyote_ticks > 0:
			found_edge = true
			break
	check(found_edge, "Coyote ledge exposes grace window")
	frame.jump_pressed = true
	frame.jump_held = true
	await ticks(1)
	check(arena.player.velocity.y < -650 and arena.player.motor.double_jump_available, "Coyote jump preserves extra jump")
	await select(4)
	await ticks(20)
	frame.movement.x = 1
	frame.jump_pressed = true
	frame.jump_held = true
	await ticks(1)
	frame.jump_pressed = false
	await ticks(20)
	frame.jump_pressed = true
	frame.movement.x = 1
	await ticks(1)
	frame.jump_pressed = false
	check(not arena.player.motor.double_jump_available and arena.player.velocity.y < -600, "Second jump consumed")
	await ticks(48)
	frame.movement.x = 0
	await ticks(25)
	check(arena.player.contacts.grounded and arena.player.position.y < 210, "Double jump reaches elevated platform")
	check(arena.player.motor.double_jump_available, "Landing refills extra jump")
	await select(5)
	await ticks(60)
	check(arena.player.motor.machine.current == PlayerStateMachine.State.WALL_SLIDE, "Wall slide station without pushing")
	check(arena.player.velocity.y <= 100.1 and arena.player.velocity.y > 0, "Wall descent capped")
	await select(6)
	await ticks(10)
	frame.jump_pressed = true
	frame.jump_held = true
	await ticks(1)
	frame.jump_pressed = false
	check(arena.player.motor.wall_lock_ticks > 0 and arena.player.velocity.x < 0, "Wall jump locks outward steering")
	await ticks(15)
	check(arena.player.position.x < 100, "Wall jump separates from wall")
	frame.movement.x = -1
	await ticks(18)
	frame.movement.x = 0
	await ticks(35)
	check(arena.player.contacts.grounded and arena.player.position.y < -170, "Wall jump alone reaches landing platform")
	for direction_index: int in 8:
		await select(7)
		arena.player.respawn_at(Vector2(0, 100))
		await ticks(2)
		var direction := Vector2.RIGHT.rotated(direction_index * PI / 4.0)
		frame.dash_direction = direction
		frame.dash_pressed = true
		await ticks(1)
		frame.dash_pressed = false
		check(arena.player.motor.dash_vector.is_equal_approx(direction), "Dash arena accepts direction %d" % direction_index)
		check(is_equal_approx(arena.player.velocity.length(), 1450), "Dash speed in arena")
	await select(8)
	await ticks(60)
	check(is_equal_approx(arena.player.velocity.y, 1400), "Shaft reaches terminal velocity")
	await ticks(120)
	check(arena.player.contacts.grounded, "Shaft has safe landing floor")
	await select(9)
	await ticks(20)
	frame.movement.x = 1
	await ticks(130)
	check(arena.player.contacts.grounded and arena.player.position.y < 80, "Walkable slope and both seams")
	await select(10)
	await ticks(40)
	check(arena.player.position.x < 620 and not arena.player.contacts.grounded, "Steep slope slides downhill")
	await select(11)
	arena.player.respawn_at(Vector2(5530, 450))
	await ticks(20)
	frame.dash_direction = Vector2.RIGHT
	frame.dash_pressed = true
	frame.movement.x = 1
	await ticks(1)
	frame.dash_pressed = false
	await ticks(20)
	check(arena.player.position.x < 5585, "High speed cannot tunnel through 8 px wall")
	await test_navigation()
	await test_surface_dash()
	await test_reset()
	arena.free()
	if failures == 0:
		print("PROJECTVELOCITY_M6_OK (%d checks; real station physics)" % checks)
	quit(0 if failures == 0 else 1)


func jump_height(held: bool) -> float:
	await select(2)
	await ticks(20)
	frame.jump_pressed = true
	frame.jump_held = true
	await ticks(1)
	frame.jump_pressed = false
	frame.jump_held = held
	frame.jump_released = not held
	await ticks(40)
	return arena.peak_rise


func test_navigation() -> void:
	await select(0)
	var key := InputEventKey.new()
	key.physical_keycode = KEY_PAGEUP
	key.pressed = true
	arena._unhandled_input(key)
	await ticks(2)
	check(arena.station_index == arena.stations.size() - 1, "Keyboard navigation wraps backward")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_RIGHT
	pad.pressed = true
	arena._unhandled_input(pad)
	await ticks(2)
	check(arena.station_index == 0, "D-pad navigation wraps forward")
	arena.request_action("death")
	await ticks(2)
	check(arena.player.motor.machine.current == PlayerStateMachine.State.DEATH, "Developer force death")
	arena.request_action("respawn")
	await ticks(2)
	check(arena.player.motor.machine.current != PlayerStateMachine.State.DEATH, "Developer respawn")
	arena.player.motor.dash_available = false
	arena.player.motor.double_jump_available = false
	arena.request_action("restore")
	await ticks(1)
	check(arena.player.motor.dash_available and arena.player.motor.double_jump_available, "Developer refill")
	var old_hint: bool = debug_collisions_hint
	arena.request_action("collision")
	await ticks(1)
	check(debug_collisions_hint != old_hint, "Collision diagnostics toggle")
	arena.request_action("collision")
	await ticks(1)


func test_reset() -> void:
	arena.player.simulation_enabled = false
	await select(4)
	var original := Vector2(200, 300)
	arena.player.position = original
	var action: StringName = arena.layer.action_name("restart")
	Input.action_press(action)
	for tick: int in 59:
		arena.sample_input()
	check(arena.player.position == original, "M6 reset requires full second")
	arena.sample_input()
	check(arena.player.position == arena.stations[4].spawn, "M6 reset uses current station")
	arena.player.position = original
	for tick: int in 80:
		arena.sample_input()
	check(arena.player.position == original, "Held reset does not repeat")
	Input.action_release(action)
	arena.sample_input()
	arena.player.position = Vector2(99999, 99999)
	arena.sample_input()
	check(arena.player.position == arena.stations[4].spawn, "Out-of-bounds returns to current station")


func test_surface_dash() -> void:
	for index: int in [0, 5]:
		await select(index)
		await ticks(20)
		var started: int = 0
		for tick: int in 60:
			frame.dash_direction = Vector2.RIGHT
			frame.dash_pressed = tick % 2 == 0
			await ticks(1)
			if arena.player.motor.events & PlayerMotor.Event.DASH_STARTED:
				started += 1
		check(started == 1 and not arena.player.motor.dash_available,
			"Real floor/wall requires detach before another Dash")
