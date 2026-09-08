extends SceneTree
## Offline real-scene collision, lifecycle, two-channel authority and bounded pool regression.

var checks: int = 0
var failures: int = 0
var observer: Observer
var world: Node2D
var a: PlayerController
var b: PlayerController
var pool: HazardWorld
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
		if is_instance_valid(pool):
			trace += "%d;" % pool.active_count()
			for projectile: HazardProjectile in pool.projectiles:
				if projectile.active:
					trace += "%s:%.4f,%.4f/%d;" % [projectile.target_player_id,
						projectile.global_position.x, projectile.global_position.y, projectile.remaining_ticks]


func revive(actor: PlayerController, location: Vector2, immunity: int = 0) -> void:
	actor.respawn_at(location)
	actor.motor.machine.transition(PlayerStateMachine.State.FALL)
	actor.motor.invulnerability_ticks = immunity


func dead(actor: PlayerController) -> bool:
	return actor.motor.machine.current == PlayerStateMachine.State.DEATH


func make_actor(location: Vector2) -> PlayerController:
	var actor := preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	actor.position = location
	actor.simulation_enabled = false
	world.add_child(actor)
	return actor


func box(location: Vector2, size: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = location
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	world.add_child(body)
	return body


func run() -> void:
	observer = Observer.new()
	observer.process_physics_priority = 200
	root.add_child(observer)
	world = Node2D.new()
	root.add_child(world)
	a = make_actor(Vector2.ZERO)
	b = make_actor(Vector2(300, 0))
	await test_configs()
	await test_areas()
	await test_pool()
	await test_channels()
	world.free()
	await test_stations()
	await process_frame
	await process_frame
	print("M9_REPLAY_HASH=" + trace.sha256_text())
	print("PROJECTVELOCITY_M9_OK checks=%d failures=%d" % [checks, failures])
	observer.queue_free()
	quit(0 if failures == 0 else 1)


func test_configs() -> void:
	var turret := TurretConfig.new()
	check(turret.validate() and is_equal_approx(turret.projectile_speed,
		PlayerMovementConfig.new().ground_max_speed * 1.2 * 1.5), "Review increases projectile speed by 50 percent")
	turret.fire_range = turret.detection_range + 1
	check(not turret.validate(), "Reject fire range outside detection")
	turret = TurretConfig.new()
	turret.projectile_speed = NAN
	check(not turret.validate(), "Reject nonfinite projectile speed")
	var caps := HazardCapsConfig.new()
	check(caps.validate() and caps.projectiles_per_target == 5 and caps.projectiles_global == 10
		and caps.engaging_turrets_per_target == 3, "Specification default caps")
	caps.projectiles_global = 0
	check(not caps.validate(), "Reject unbounded/empty pool")
	var laser := LaserConfig.new()
	laser.telegraph_duration = 0
	check(not laser.validate(), "Cyclic hazards require positive warning")
	var saw := SawConfig.new()
	saw.moving = true
	saw.path = null
	check(not saw.validate(), "Moving saw requires valid route")
	var spikes := SpikeConfig.new()
	spikes.trigger_size.x = -1
	check(not spikes.validate(), "Reject invalid local sensor")
	var phased := Laser.new()
	phased.config = LaserConfig.new()
	phased.config.phase_offset = 1.5
	world.add_child(phased)
	check(phased.state == CycleHazard.State.TELEGRAPH, "Authored phase offset starts at warning boundary")
	phased.free()


func test_areas() -> void:
	var zone := preload("res://gameplay/race/death_zone.tscn").instantiate() as DeathZone
	world.add_child(zone)
	revive(a, Vector2.ZERO, 3)
	await ticks(3)
	check(not dead(a), "DeathZone respects invulnerability")
	a.motor.invulnerability_ticks = 0
	await ticks(1)
	check(dead(a), "DeathZone rechecks persistent overlap")
	zone.free()
	for mode: int in SpikeConfig.Mode.values():
		var spikes := preload("res://gameplay/hazards/spikes.tscn").instantiate() as Spikes
		spikes.config = SpikeConfig.new()
		spikes.config.mode = mode as SpikeConfig.Mode
		spikes.config.inactive_duration = 0.1
		spikes.config.telegraph_duration = 0.1
		spikes.config.active_duration = 0.1
		world.add_child(spikes)
		revive(a, Vector2.ZERO)
		await ticks(3)
		if mode == SpikeConfig.Mode.STATIC:
			check(dead(a) and spikes.lethal, "Static spikes actual collision")
		else:
			check(not dead(a) and spikes.state == CycleHazard.State.INACTIVE, "Retracted spikes safe")
			if mode == SpikeConfig.Mode.TRIGGER:
				spikes.set_trigger(true)
			else:
				await ticks(3)
			await ticks(1)
			check(spikes.state == CycleHazard.State.TELEGRAPH and not dead(a), "Spikes warn before extension")
			await ticks(6)
			check(spikes.lethal and dead(a), "Extended spikes kill persistent occupant")
			if mode == SpikeConfig.Mode.TRIGGER:
				spikes.set_trigger(false)
				await ticks(1)
				check(not spikes.lethal, "Local falling edge retracts")
				spikes.set_trigger(true)
				await ticks(1)
				check(spikes.state == CycleHazard.State.TELEGRAPH, "Re-trigger starts full warning")
			else:
				await ticks(6)
				check(not spikes.lethal, "Timed spikes retract cyclically")
		spikes.free()
	var sensor_spikes := Spikes.new()
	sensor_spikes.config = SpikeConfig.new()
	sensor_spikes.config.mode = SpikeConfig.Mode.TRIGGER
	sensor_spikes.config.trigger_on_player_overlap = true
	world.add_child(sensor_spikes)
	revive(a, sensor_spikes.config.trigger_offset)
	await ticks(3)
	check(sensor_spikes.trigger_requested and not dead(a), "Real local trigger sensor starts warning")
	a.position = Vector2(-600, 0)
	await ticks(3)
	check(not sensor_spikes.trigger_requested, "Leaving local sensor retracts")
	sensor_spikes.free()
	for mode: int in LaserConfig.Mode.values():
		var laser := preload("res://gameplay/hazards/laser.tscn").instantiate() as Laser
		laser.config = LaserConfig.new()
		laser.config.mode = mode as LaserConfig.Mode
		laser.config.inactive_duration = 0
		laser.config.telegraph_duration = 0.1
		laser.config.active_duration = 0.1
		world.add_child(laser)
		revive(a, Vector2.ZERO)
		await ticks(3)
		if mode == LaserConfig.Mode.CYCLIC:
			check(not dead(a) and laser.state == CycleHazard.State.TELEGRAPH, "Cyclic laser has nonlethal warning")
			await ticks(4)
		check(dead(a) and laser.lethal, "Both laser modes fatal through M7 path")
		revive(a, Vector2.ZERO, 45)
		await ticks(2)
		check(not dead(a), "Both laser modes honor immunity")
		laser.free()
	for moving: bool in [false, true]:
		var saw := preload("res://gameplay/hazards/saw.tscn").instantiate() as Saw
		saw.config = SawConfig.new()
		saw.config.moving = moving
		saw.config.path = MovingPlatformConfig.new()
		saw.config.path.route = PackedVector2Array([Vector2.ZERO, Vector2(100, 0)])
		saw.config.path.waits = PackedFloat32Array([0, 0])
		saw.config.path.speed = 60
		world.add_child(saw)
		revive(a, Vector2.ZERO, 45)
		await ticks(3)
		check(not dead(a), "Saw respects invulnerability")
		a.motor.invulnerability_ticks = 0
		await ticks(2)
		check(dead(a), "Both saw modes kill via actual circular collision")
		a.position = Vector2(-600, 0)
		await ticks(60)
		check(saw.position.x > 60 if moving else saw.position == Vector2.ZERO, "Saw static/path movement")
		saw.free()
	# M7 safety rejects inactive hazards too; successful respawn uses permanent ground.
	var floor_body: StaticBody2D = box(Vector2(0, 100), Vector2(1400, 40))
	var reserved := Spikes.new()
	reserved.config = SpikeConfig.new()
	reserved.config.mode = SpikeConfig.Mode.TRIGGER
	reserved.position = Vector2(0, 68)
	world.add_child(reserved)
	a.simulation_enabled = true
	revive(a, Vector2(0, 46))
	await ticks(3)
	check(not RespawnSafety.valid(a, Vector2(0, 46)), "Retracted hazard reserves respawn clearance")
	check(RespawnSafety.valid(a, Vector2(-300, 46)), "Nearby clear static floor accepted")
	var life := PlayerLifecycle.new()
	world.add_child(life)
	life.bind(a, Vector2(-300, 46))
	life.respawn_position = Vector2(0, 46)
	a.die(true)
	await ticks(28)
	check(not dead(a) and a.position == Vector2(-300, 46) and a.motor.invulnerability_ticks == 45,
		"Hazard-invalid checkpoint falls back to safe M7 start with immunity")
	life.free()
	reserved.free()
	floor_body.free()
	a.simulation_enabled = false


func test_pool() -> void:
	pool = HazardWorld.new()
	pool.position = Vector2(75, 90)
	pool.rotation = PI / 2
	world.add_child(pool)
	check(pool.register_player(&"a", a) and pool.register_player(&"b", b), "Explicit independent player channels")
	check(not pool.register_player(&"duplicate", a) and not pool.register_player(&"a", b), "Duplicate identities/actors rejected")
	check(a.input_layer == null and b.input_layer == null, "Two actors do not require physical InputLayer")
	var config := TurretConfig.new()
	b.presentation.is_local = false
	revive(a, Vector2(400, 0))
	revive(b, Vector2(100, 0))
	await ticks(2)
	var shot: HazardProjectile = pool.fire(&"a", Vector2.ZERO, Vector2.RIGHT, config, 1)
	check(shot.self_modulate.a == 1.0 and is_equal_approx(shot.velocity.length(), 1224),
		"Local target round is opaque and uses faster default speed")
	check(shot.global_transform == Transform2D.IDENTITY, "World-space projectile ignores transformed pool parent")
	await ticks(8)
	check(not dead(b) and shot.active, "Projectile crosses nondesignated real player without killing or retiring")
	await ticks(22)
	check(dead(a) and not shot.active and pool.active_count() == 0, "Confirmed designated collision returns round")
	check(shot.target_player_id == &"" and shot.source_id == 0 and shot.velocity == Vector2.ZERO
		and shot.remaining_ticks == 0 and not shot.visible, "Returned round clears all target/motion/lifetime/visual state")
	revive(a, Vector2(400, 0), 45)
	var reuse: HazardProjectile = pool.fire(&"b", Vector2.ZERO, Vector2.RIGHT, config, 2)
	check(is_equal_approx(reuse.self_modulate.a, 0.3)
		and reuse.self_modulate.a == b.presentation.modulate.a, "Opponent round matches actor opacity")
	check(reuse == shot and reuse.target_player_id == &"b", "Same pooled object binds a different target")
	await ticks(10)
	check(dead(b) and pool.active_count() == 0, "Reused collider clears prior exceptions")
	revive(a, Vector2(100, 0), 45)
	shot = pool.fire(&"a", Vector2.ZERO, Vector2.RIGHT, config, 1)
	check(shot == reuse and shot.self_modulate.a == 1.0, "Reusing opponent round for local target restores opacity")
	await ticks(12)
	check(not dead(a) and shot.active, "Unconfirmed invulnerable target hit does not consume round")
	pool.retire_target(&"a")
	revive(a, Vector2(300, 0))
	var wall: StaticBody2D = box(Vector2(120, 0), Vector2(2, 100))
	await ticks(2)
	config.projectile_speed = 60000
	shot = pool.fire(&"a", Vector2.ZERO, Vector2.RIGHT, config, 1)
	await ticks(1)
	check(not shot.active and not dead(a), "Swept fast round hits 2px blocking wall before target")
	wall.free()
	await ticks(2)
	shot = pool.fire(&"a", Vector2.ZERO, Vector2.RIGHT, config, 1)
	await ticks(1)
	check(dead(a) and not shot.active, "Swept fast round hits designated capsule without tunneling")
	config = TurretConfig.new()
	config.projectile_speed = 1
	config.projectile_lifetime = 0.05
	revive(a, Vector2(400, 0))
	revive(b, Vector2(400, 200))
	var objects: Array[int] = []
	for projectile: HazardProjectile in pool.projectiles:
		objects.append(projectile.get_instance_id())
	for cycle: int in 50:
		for index: int in 5:
			check(pool.fire(&"a", Vector2.ZERO, Vector2.LEFT, config, 1) != null, "Per-target cap allows round")
		check(pool.fire(&"a", Vector2.ZERO, Vector2.LEFT, config, 1) == null, "Sixth target round skipped")
		for index: int in 5:
			pool.fire(&"b", Vector2.ZERO, Vector2.LEFT, config, 2)
		check(pool.active_count() == 10, "Two targets share global ten object bound")
		await ticks(4)
		check(pool.active_count() == 0, "Lifetime returns all missed rounds without leaks")
	for index: int in objects.size():
		check(objects[index] == pool.projectiles[index].get_instance_id(), "Repeated cycles never allocate new projectile nodes")
	check(pool.get_child_count() == 10, "Pool owns exactly ten projectile nodes after stress")
	config.projectile_lifetime = 5
	pool.fire(&"a", Vector2.ZERO, Vector2.LEFT, config, 1)
	pool.fire(&"b", Vector2.ZERO, Vector2.LEFT, config, 2)
	a.die()
	check(pool.active_count(&"a") == 0 and pool.active_count(&"b") == 1, "Target death retires only its own channel")
	b.free()
	check(pool.active_count() == 0 and not pool.players.has(&"b"), "Target deletion unregisters and returns rounds")
	b = make_actor(Vector2(400, 200))
	check(pool.register_player(&"b", b), "Deleted identity can register fresh actor")
	pool.fire(&"b", Vector2.ZERO, Vector2.LEFT, config, 2)
	b.respawn_at(Vector2(400, 200))
	check(pool.active_count() == 0, "Relocation cannot retain shots from previous life")
	pool.free()
	pool = HazardWorld.new()
	pool.caps = HazardCapsConfig.new()
	pool.caps.projectiles_per_target = 4
	pool.caps.projectiles_global = 3
	pool.caps.engaging_turrets_per_target = 1
	world.add_child(pool)
	pool.register_player(&"a", a)
	pool.register_player(&"b", b)
	revive(a, Vector2(400, 0))
	revive(b, Vector2(400, 200))
	pool.fire(&"a", Vector2.ZERO, Vector2.LEFT, config, 1)
	pool.fire(&"a", Vector2.ZERO, Vector2.LEFT, config, 1)
	pool.fire(&"b", Vector2.ZERO, Vector2.LEFT, config, 2)
	check(pool.fire(&"b", Vector2.ZERO, Vector2.LEFT, config, 2) == null,
		"Configured global cap enforced independently of target cap")
	check(pool.acquire(&"a", 1) and not pool.acquire(&"a", 2) and pool.acquire(&"b", 2),
		"Configured engagement cap and per-player independence")
	pool.release(&"a", 1)
	check(pool.acquire(&"a", 2), "Released engagement slot reusable")
	pool.free()
	pool = null


func test_channels() -> void:
	pool = HazardWorld.new()
	world.add_child(pool)
	pool.register_player(&"a", a)
	pool.register_player(&"b", b)
	revive(a, Vector2(400, -14), 999)
	revive(b, Vector2(400, 14), 999)
	var turret := preload("res://gameplay/hazards/turret.tscn").instantiate() as Turret
	turret.config = TurretConfig.new()
	turret.config.telegraph_duration = 0.1
	turret.config.aim_turn_speed = 60
	turret.config.cooldown = 0.01
	turret.config.minimum_cooldown = 0.3
	turret.config.projectile_speed = 1
	check(turret.bind(pool, [&"a", &"b"]), "Dual barrel explicitly bound")
	world.add_child(turret)
	var channel: TurretChannel = turret.channels[0]
	await ticks(1)
	check(channel.state == TurretChannel.State.LINE_OF_SIGHT, "Detection precedes LOS")
	await ticks(1)
	check(channel.state == TurretChannel.State.AIM, "LOS precedes aim")
	await ticks(1)
	check(channel.state == TurretChannel.State.TELEGRAPH and pool.active_count() == 0, "Aim precedes visible warning")
	var locked_angle: float = channel.angle
	a.velocity = Vector2(0, 1000)
	await ticks(5)
	check(channel.state == TurretChannel.State.TELEGRAPH and channel.angle == locked_angle,
		"Full telegraph duration and locked displayed direction")
	await ticks(1)
	check(channel.state == TurretChannel.State.FIRE, "Explicit fire state after warning")
	await ticks(1)
	check(pool.active_count() == 2 and turret.channels[0].shots == 1 and turret.channels[1].shots == 1,
		"Both independent barrels fire on same physics tick")
	check(channel.state == TurretChannel.State.COOLDOWN and channel.remaining_ticks == 18,
		"Minimum cooldown clamps configured cadence")
	a.velocity = Vector2.ZERO
	# Fill each channel, then verify skipped shots never queue a delayed burst.
	for index: int in 4:
		pool.fire(&"a", Vector2.ZERO, Vector2.LEFT, turret.config, turret.get_instance_id())
		pool.fire(&"b", Vector2.ZERO, Vector2.LEFT, turret.config, turret.get_instance_id())
	await ticks(28)
	check(channel.skipped == 1 and channel.state == TurretChannel.State.COOLDOWN
		and pool.active_count() == 10, "Cap skip enters ordinary cooldown with no extra object")
	pool.projectiles[0].recycle()
	await ticks(5)
	check(channel.shots == 1 and pool.active_count() == 9, "Freeing slot does not enqueue deferred shot")
	var shot: HazardProjectile = pool.projectiles[1]
	turret.free()
	check(pool.active_count() == 0 and not shot.active and pool.engagements[&"a"].is_empty(),
		"Destroying turret releases leases and its live rounds")
	# Real geometry blocks LOS; death/Finish/range losses cancel telegraphs.
	turret = Turret.new()
	turret.config = TurretConfig.new()
	turret.config.aim_turn_speed = 60
	turret.bind(pool, [&"a", &"b"])
	world.add_child(turret)
	var wall: StaticBody2D = box(Vector2(200, 0), Vector2(20, 200))
	await ticks(10)
	check(pool.active_count() == 0 and pool.engagements[&"a"].is_empty(), "World collider blocks LOS and engagement")
	wall.free()
	await ticks(6)
	check(turret.channels[0].state == TurretChannel.State.TELEGRAPH, "Removing blocker allows aim and warning")
	a.position = Vector2(1000, 0)
	await ticks(1)
	check(turret.channels[0].state == TurretChannel.State.DETECTION, "Leaving fire range cancels warning inside detection range")
	a.position = Vector2(2000, 0)
	await ticks(3)
	check(turret.channels[0].state == TurretChannel.State.DETECTION, "Detection range rejects distant actor")
	a.position = Vector2(400, -14)
	await ticks(4)
	a.die(true)
	await ticks(1)
	check(turret.channels[0].state == TurretChannel.State.DETECTION and pool.engagements[&"a"].is_empty(),
		"Death cancels in-progress warning and lease")
	b.finish_run()
	await ticks(1)
	check(turret.channels[1].state == TurretChannel.State.DETECTION, "Finish cancels other barrel independently")
	turret.free()
	revive(a, Vector2(400, 0), 999)
	revive(b, Vector2(400, 60), 999)
	var turrets: Array[Turret] = []
	for index: int in 4:
		var item := Turret.new()
		item.config = TurretConfig.new()
		item.config.telegraph_duration = 5
		item.config.aim_turn_speed = 60
		item.bind(pool, [&"a", &"b"])
		world.add_child(item)
		turrets.append(item)
	await ticks(6)
	check(pool.engagements[&"a"].size() == 3 and pool.engagements[&"b"].size() == 3,
		"Four real turrets enforce default three engagements on each player")
	check(turrets[3].channels[0].state == TurretChannel.State.LINE_OF_SIGHT, "Fourth turret waits without warning/fire")
	turrets[0].free()
	await ticks(3)
	check(turrets[3].channels[0].state == TurretChannel.State.TELEGRAPH, "Freed engagement permits waiting turret")
	for index: int in range(1, 4):
		turrets[index].free()
	var tuning := TurretConfig.new()
	a.velocity = Vector2(100000, 0)
	check(tuning.lead_point(Vector2.ZERO, a.position, a.velocity).distance_to(a.position) <= tuning.maximum_lead_distance + 0.001,
		"Velocity lead is distance limited")
	tuning.aim_lead_factor = 0
	check(tuning.lead_point(Vector2.ZERO, a.position, a.velocity) == a.position, "Zero lead aims at current target")
	tuning.aim_lead_factor = 1
	tuning.maximum_lead_distance = 10000
	a.velocity = Vector2(100, 0)
	check(is_equal_approx(tuning.lead_point(Vector2(-10000, 0), a.position, a.velocity).x
		- a.position.x, 50), "Lead time capped independently of displacement")
	a.velocity = Vector2.ZERO
	revive(a, Vector2(400, -14), 999)
	revive(b, Vector2(400, 14), 999)
	turret = Turret.new()
	turret.config = TurretConfig.new()
	turret.config.aim_turn_speed = 60
	turret.config.telegraph_duration = 0.05
	turret.config.projectile_speed = 1
	turret.barrel_two_config = turret.config.duplicate() as TurretConfig
	turret.barrel_two_config.telegraph_duration = 0.5
	turret.bind(pool, [&"a", &"b"])
	world.add_child(turret)
	await ticks(9)
	check(turret.channels[0].shots == 1 and turret.channels[1].shots == 0
		and turret.channels[1].state == TurretChannel.State.TELEGRAPH,
		"Independent barrel override preserves another channel's longer warning")
	wall = box(Vector2(200, 0), Vector2(20, 200))
	await ticks(3)
	check(turret.channels[1].state == TurretChannel.State.DETECTION,
		"New LOS obstruction cancels warning before fire")
	wall.free()
	turret.free()
	turret = Turret.new()
	turret.config = TurretConfig.new()
	turret.config.aim_turn_speed = 0.6
	turret.bind(pool, [&"a", &"b"])
	a.position = Vector2(0, 400)
	world.add_child(turret)
	await ticks(3)
	check(is_equal_approx(turret.channels[0].angle, 0.01)
		and turret.channels[0].state == TurretChannel.State.AIM, "Aim turn speed respects fixed-tick angular limit")
	a.start_blocked = true
	await ticks(1)
	check(turret.channels[0].state == TurretChannel.State.DETECTION, "Start barrier suppresses channel attacks")
	a.start_blocked = false
	turret.free()
	var extra: PlayerController = make_actor(Vector2(900, 900))
	check(not pool.register_player(&"third", extra), "Offline two-player roster is bounded")
	extra.free()
	pool.free()
	pool = null


func test_stations() -> void:
	var arena := preload("res://dev_tools/test_playground.tscn").instantiate() as TestPlayground
	root.add_child(arena)
	for index: int in range(16, 22):
		arena.request_station(index)
		await ticks(3)
		check(arena.hazards != null and not arena.hazards.modules.is_empty(), "M9 station contains actual modular hazards")
		if index < 20:
			var module: Node2D = arena.hazards.modules[0]
			arena.player.respawn_at(module.global_position)
			arena.player.motor.invulnerability_ticks = 0
			await ticks(3)
			check(dead(arena.player), "Actual playground module collision uses lifecycle death")
			await ticks(30)
			check(not dead(arena.player) and arena.player.position.x == 0, "Playground hazard death safely respawns")
		else:
			check(arena.hazards.opponent.input_layer == null, "Offline opponent never owns physical input")
			await ticks(200)
			var authority: HazardWorld = arena.hazards.authority
			check(authority.active_count() <= 10 and authority.get_child_count() == 10, "Live station pool remains bounded")
			var projectile: HazardProjectile = authority.projectiles[0]
			arena.request_station(0)
			await ticks(2)
			check(not is_instance_valid(authority) and not is_instance_valid(projectile), "Station switch destroys pool and all projectile objects")
	for cycle: int in 12:
		arena.request_station(21)
		await ticks(30)
		var previous: HazardPlayground = arena.hazards
		arena.request_station(0)
		await ticks(2)
		check(not is_instance_valid(previous) and arena.player.died.get_connections().is_empty(),
			"Repeated station teardown releases lifecycle callbacks and authority references")
	arena.free()
