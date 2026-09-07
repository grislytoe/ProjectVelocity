extends SceneTree
## Rendered jitter check: track a marker attached to a steadily moving real controller.


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(5000, 650)
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20000, 100)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	floor_body.add_child(collision)
	root.add_child(floor_body)
	var player: PlayerController = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.position = Vector2(100, 500)
	player.input_provider = moving_frame
	root.add_child(player)
	var marker := Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)])
	marker.color = Color.MAGENTA
	marker.z_index = 10
	player.add_child(marker)
	var camera := LocalPlayerCamera.new()
	root.add_child(camera)
	camera.follow_local(player)
	if OS.get_cmdline_user_args().has("--negative-control"):
		player.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	for tick: int in 240:
		await physics_frame
	var minimum_x: float = INF
	var maximum_x: float = -INF
	for frame: int in 32:
		await RenderingServer.frame_post_draw
		var screenshot: Image = root.get_texture().get_image()
		var total_x: float = 0
		var count: int = 0
		for y: int in range(screenshot.get_height() / 2 - 140, screenshot.get_height() / 2 + 140):
			for x: int in range(screenshot.get_width() / 2 - 180, screenshot.get_width() / 2 + 100):
				var color: Color = screenshot.get_pixel(x, y)
				if color.r > 0.9 and color.b > 0.9 and color.g < 0.1:
					total_x += x
					count += 1
		if count == 0 or player.velocity.x < 650:
			push_error("Motion marker missing or player not moving")
			quit(1)
			return
		var center_x: float = total_x / count
		minimum_x = minf(minimum_x, center_x)
		maximum_x = maxf(maximum_x, center_x)
		if frame == 31:
			var suffix: String = "-negative" if OS.get_cmdline_user_args().has("--negative-control") else ""
			screenshot.save_png("res://builds/validation/m5-motion%s.png" % suffix)
	print("M5_RENDERED_JITTER_PX=%.3f" % (maximum_x - minimum_x))
	if maximum_x - minimum_x > 1.5:
		push_error("Camera/player screen-space jitter exceeds 1.5 px")
		quit(1)
		return
	print("PROJECTVELOCITY_M5_RENDER_OK (32 moving rendered frames)")
	quit(0)


func moving_frame() -> InputFrame:
	var frame := InputFrame.new()
	frame.movement.x = 1
	return frame
