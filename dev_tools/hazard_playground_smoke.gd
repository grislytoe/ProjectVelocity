extends SceneTree
## Normal renderer screenshots of all six M9 stations; isolated from saves.


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	TranslationServer.set_locale("ru")
	var arena := preload("res://dev_tools/test_playground.tscn").instantiate() as TestPlayground
	root.add_child(arena)
	for index: int in range(16, 22):
		arena.request_station(index)
		for tick: int in (100 if index >= 20 else 25):
			await physics_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png("res://builds/m9-station-%02d.png" % index) != OK:
			push_error("Cannot save M9 renderer screenshot")
			quit(1)
			return
	print("PROJECTVELOCITY_M9_RENDER_OK (six stations; Russian HUD)")
	arena.free()
	quit()
