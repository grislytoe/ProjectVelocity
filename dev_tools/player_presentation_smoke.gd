extends SceneTree
## Normal-renderer check of the isolated arena; never opens a user save.


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var arena: Node = preload("res://dev_tools/player_playground.tscn").instantiate()
	root.add_child(arena)
	for tick: int in 60:
		await physics_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://builds/validation")
	if screenshot.is_empty() or screenshot.save_png("res://builds/validation/m3-playground.png") != OK:
		push_error("M3 renderer screenshot failed")
		quit(1)
		return
	print("PROJECTVELOCITY_M3_PRESENTATION_OK")
	quit(0)
