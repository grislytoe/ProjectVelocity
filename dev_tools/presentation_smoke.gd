extends SceneTree
## Run with a real renderer; captures the placeholder for visual review.

func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var scene: PackedScene = load("res://core/bootstrap/main.tscn") as PackedScene
	root.add_child(scene.instantiate())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	var result: Error = screenshot.save_png("res://builds/validation/placeholder.png")
	if result != OK:
		push_error("Could not save placeholder screenshot")
		quit(1)
		return
	print("PROJECTVELOCITY_RENDER_OK")
	quit(0)
