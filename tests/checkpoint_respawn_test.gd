extends SceneTree

var checks: int = 0
var failures: int = 0
var arena: LifecyclePlayground
var observer: Observer

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


func run() -> void:
	var progress := CheckpointProgress.new()
	check(not progress.configure([&"a", &"a"], []), "Duplicate course rejected")
	check(not progress.configure([&"a"], [&"unknown"]), "Unknown mandatory rejected")
	check(progress.configure([&"a", &"b", &"optional"], [&"a", &"b"]), "Valid course")
	check(not progress.activate(&"b") and not progress.can_finish(), "Strict order blocks skip")
	check(progress.activate(&"a") and not progress.activate(&"a"), "Idempotent activation")
	check(progress.activate(&"b") and progress.can_finish(), "Optional not required to finish")
	var other := CheckpointProgress.new()
	other.configure([&"a", &"b"], [&"a", &"b"], false)
	check(other.activate(&"b") and not other.can_finish(), "Unordered still enforces mandatory")
	check(other.activate(&"a") and other.can_finish(), "Unordered completion")
	check(progress.reached.size() == 2, "Per-player isolation")
	var gate := ReadyStart.new()
	check(not gate.configure([]) and not gate.configure([&"a", &"a"]), "Invalid roster")
	gate.configure([&"host", &"guest"])
	gate.set_ready(&"host", true)
	check(not gate.schedule(100, 0), "Both loaded and ready required")
	check(not gate.set_ready(&"stranger", true), "Unknown participant rejected")
	gate.set_ready(&"guest", true)
	check(not gate.schedule(0, 0) and gate.schedule(100, 0), "Future authority tick required")
	gate.set_ready(&"guest", false)
	check(not gate.advance(100), "Unreadiness cancels schedule")
	gate.set_ready(&"guest", true)
	gate.schedule(150, 100)
	check(not gate.advance(149) and gate.advance(150) and not gate.advance(151), "GO exactly once")
	arena = preload("res://dev_tools/lifecycle_playground.tscn").instantiate() as LifecyclePlayground
	root.add_child(arena)
	observer = Observer.new()
	observer.process_physics_priority = 200
	root.add_child(observer)
	var player: PlayerController = arena.player
	var lifecycle: PlayerLifecycle = arena.lifecycle
	var move := InputFrame.new()
	move.movement.x = 1
	move.dash_pressed = true
	move.dash_direction = Vector2.RIGHT
	player.input_provider = func() -> InputFrame: return move
	await ticks(100)
	check(player.position == lifecycle.start_position, "Barrier blocks movement and Dash")
	check(not lifecycle.checkpoint(&"a", Vector2(290, 566)) and not lifecycle.finish(), "No progress before GO")
	player.input_provider = func() -> InputFrame: return InputFrame.new()
	await ticks(90)
	check(not player.start_blocked, "Barrier releases player")
	check(RespawnSafety.valid(player, Vector2(290, 566)), "Full capsule safe static floor")
	check(not RespawnSafety.valid(player, Vector2(290, 600)), "Embedded spawn rejected")
	check(not RespawnSafety.valid(player, Vector2(290, 300)), "Unsupported spawn rejected")
	check(not RespawnSafety.valid(player, Vector2(680, 566)), "Fatal overlap rejected")
	var moving := AnimatableBody2D.new()
	moving.position = Vector2(2000, 400)
	arena.add_box(moving, Vector2(200, 40), Color.WHITE)
	await ticks(2)
	check(not RespawnSafety.valid(player, Vector2(2000, 346)), "Moving platform spawn rejected")
	check(not lifecycle.checkpoint(&"b", Vector2(940, 566)), "Trigger rejects out of order")
	var before: Vector2 = player.position
	check(not lifecycle.finish() and player.position == before, "Invalid finish never teleports")
	check(lifecycle.checkpoint(&"a", Vector2(290, 566)), "Safe checkpoint activates")
	check(not lifecycle.checkpoint(&"b", Vector2(680, 566)), "Unsafe checkpoint not credited")
	await ticks(45)
	check(player.die() and not player.die(), "Death is idempotent")
	await ticks(27)
	check(player.motor.machine.current == PlayerStateMachine.State.DEATH, "Disintegration lasts 0.45 seconds")
	await ticks(1)
	check(player.position == Vector2(290, 566), "Respawn at per-player checkpoint")
	check(player.velocity == Vector2.ZERO and player.motor.dash_available and player.motor.double_jump_available,
		"Respawn resets velocity and abilities")
	check(player.motor.invulnerability_ticks == 45 and not player.die(), "45 ticks fatal invulnerability")
	check(player.collision_mask == 1, "Level collision retained")
	await ticks(45)
	check(player.die(), "Invulnerability expires")
	# Obstruct checkpoint after activation: fallback to Start.
	var blocker := StaticBody2D.new()
	blocker.position = Vector2(290, 550)
	arena.add_box(blocker, Vector2(80, 80), Color.WHITE)
	await ticks(28)
	check(player.position == lifecycle.start_position, "Invalidated checkpoint falls back to Start")
	await ticks(46)
	var start_blocker := StaticBody2D.new()
	start_blocker.position = Vector2(0, 550)
	arena.add_box(start_blocker, Vector2(80, 80), Color.WHITE)
	player.die()
	await ticks(35)
	check(player.motor.machine.current == PlayerStateMachine.State.DEATH, "No unsafe fallback teleport")
	start_blocker.queue_free()
	await ticks(3)
	check(player.motor.machine.current != PlayerStateMachine.State.DEATH, "Blocked respawn retries safely")
	blocker.queue_free()
	await ticks(46)
	player.respawn_at(Vector2(680, 566))
	await ticks(47)
	check(player.motor.machine.current == PlayerStateMachine.State.DEATH, "Persistent hazard kills after immunity")
	await ticks(29)
	await ticks(2)
	check(lifecycle.checkpoint(&"b", Vector2(940, 566)), "Remaining mandatory accepted")
	check(lifecycle.finish() and not lifecycle.finish() and not player.die(true), "Validated finish once; finished actor immune")
	var opponent: PlayerController = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	opponent.position = Vector2(240, 250)
	arena.add_child(opponent)
	opponent.presentation.is_local = false
	var opponent_life := PlayerLifecycle.new()
	arena.add_child(opponent_life)
	opponent_life.bind(opponent, opponent.position)
	opponent_life.progress.configure([&"a", &"b"], [&"a", &"b"])
	for checkpoint: CheckpointTrigger in arena.checkpoints:
		checkpoint.players[opponent] = opponent_life
	arena.finish.players[opponent] = opponent_life
	var walking := InputFrame.new()
	walking.movement.x = 1
	opponent.input_provider = func() -> InputFrame: return walking
	await ticks(25)
	check(opponent_life.progress.reached == [&"a"], "Tall checkpoint catches second player above former trigger")
	check(lifecycle.progress.can_finish() and not opponent_life.progress.can_finish(), "Independent physical players retain distinct progress")
	opponent.input_provider = func() -> InputFrame: return InputFrame.new()
	opponent.position = Vector2(1330, 566)
	await ticks(3)
	check(opponent.motor.machine.current != PlayerStateMachine.State.FINISH, "Real finish Area rejects missing checkpoint")
	opponent.position = Vector2(990, 566)
	await ticks(3)
	check(opponent_life.progress.can_finish(), "Second checkpoint Area activates")
	opponent.position = Vector2(1330, 566)
	await ticks(3)
	check(opponent.motor.machine.current == PlayerStateMachine.State.FINISH, "Real finish Area validates complete route")
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		check(tr("M7_SKIPPED_CHECKPOINT") != "M7_SKIPPED_CHECKPOINT", "Localized validation")
	if "--render-smoke" in OS.get_cmdline_user_args():
		await process_frame
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png("res://builds/m7-lifecycle.png") == OK, "Renderer screenshot")
	print("PROJECTVELOCITY_M7_OK checks=%d failures=%d" % [checks, failures])
	arena.queue_free()
	observer.queue_free()
	quit(0 if failures == 0 else 1)
