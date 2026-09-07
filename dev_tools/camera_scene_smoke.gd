extends SceneTree


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var scene: Node2D = preload("res://dev_tools/camera_playground.tscn").instantiate()
	root.add_child(scene)
	var positions: Array[Vector2] = [Vector2(150, 500), Vector2(1450, 450), Vector2(2400, 700)]
	for index: int in positions.size():
		scene.player.respawn_at(positions[index])
		for tick: int in 15:
			await physics_frame
		await RenderingServer.frame_post_draw
		var ratio: float = 64 * scene.camera.zoom.y / root.get_visible_rect().size.y
		if ratio < 0.05 or ratio > 0.07:
			push_error("Camera fixture scale outside target framing")
			quit(1)
			return
		var screenshot: Image = root.get_texture().get_image()
		if screenshot.save_png("res://builds/validation/m5-zone-%d.png" % index) != OK:
			push_error("Camera fixture capture failed")
			quit(1)
			return
	print("PROJECTVELOCITY_M5_SCENE_OK (default, zoom, lock framing)")
	quit(0)
