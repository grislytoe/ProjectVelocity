extends SceneTree
## Exercise the actual arena input adapter, without running movement or opening saves.

var failures: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)


func run() -> void:
	var arena: Node2D = preload("res://dev_tools/player_playground.tscn").instantiate()
	root.add_child(arena)
	arena.player.simulation_enabled = false
	var action: StringName = arena.layer.action_name("restart")
	var original := Vector2(400, 300)
	arena.player.position = original
	Input.action_press(action)
	for tick: int in 59:
		arena.sample_input()
	check(arena.player.position == original, "No reset before one second")
	Input.action_release(action)
	arena.sample_input()
	Input.action_press(action)
	for tick: int in 59:
		arena.sample_input()
	check(arena.player.position == original, "Interrupted holds do not accumulate")
	arena.sample_input()
	check(arena.player.position == Vector2(150, 500), "Reset on tick 60")
	arena.player.position = original
	for tick: int in 120:
		arena.sample_input()
	check(arena.player.position == original, "Continued hold does not repeat reset")
	Input.action_release(action)
	arena.sample_input()
	Input.action_press(action)
	for tick: int in 60:
		arena.sample_input()
	check(arena.player.position == Vector2(150, 500), "Release rearms another full hold")
	Input.action_release(action)
	arena.player.position = Vector2(400, 1700)
	arena.sample_input()
	check(arena.player.position == Vector2(150, 500), "Out-of-bounds recovery remains immediate")
	arena.free()
	if failures == 0:
		print("PROJECTVELOCITY_M3_RESTART_OK (6 checks)")
	quit(0 if failures == 0 else 1)
