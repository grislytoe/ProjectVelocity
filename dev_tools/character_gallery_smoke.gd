extends SceneTree


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var gallery: Node2D = preload("res://dev_tools/character_gallery.tscn").instantiate()
	root.add_child(gallery)
	for tick: int in 8:
		await physics_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute("res://builds/validation")
	if screenshot.is_empty() or screenshot.save_png("res://builds/validation/m4-gallery.png") != OK:
		push_error("M4 gallery render failed")
		quit(1)
		return
	print("PROJECTVELOCITY_M4_RENDER_OK")
	quit(0)
