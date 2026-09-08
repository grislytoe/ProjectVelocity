extends SceneTree
## Normal-renderer fixture smoke and screenshots. No real save is opened.


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	TranslationServer.set_locale("ru")
	var arena: TestPlayground = preload("res://dev_tools/test_playground.tscn").instantiate() as TestPlayground
	root.add_child(arena)
	for index: int in [0, 4, 7, 8, 9, 11, 12, 13, 14, 15]:
		arena.request_station(index)
		for tick: int in 12:
			await physics_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var path: String = "res://builds/m6-station-%02d.png" % index
		if root.get_texture().get_image().save_png(path) != OK:
			push_error("Cannot save playground screenshot")
			quit(1)
			return
	print("PROJECTVELOCITY_M6_RENDER_OK (10 stations; Russian HUD)")
	arena.free()
	quit()
