extends SceneTree
## Run with a real renderer; captures the placeholder for visual review.

func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var scene: PackedScene = load("res://core/bootstrap/main.tscn") as PackedScene
	var main: Node = scene.instantiate()
	var save_path: String = OS.get_cache_dir().path_join(
		"project_velocity_render-test-" + PlayerProfileData.new_uuid())
	main.save_store = SaveStore.new(save_path)
	root.add_child(main)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	var result: Error = screenshot.save_png("res://builds/validation/placeholder.png")
	DirAccess.remove_absolute(save_path.path_join("save.json"))
	DirAccess.remove_absolute(save_path)
	if result != OK:
		push_error("Could not save placeholder screenshot")
		quit(1)
		return
	print("PROJECTVELOCITY_RENDER_OK")
	quit(0)
