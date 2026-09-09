extends SceneTree
## Real renderer, isolated save, GUI navigation and actual motor-driven course completion.

var ui: AppUI
var jump_one: bool = false
var jump_two: bool = false
var dashed: bool = false
var folder: String

func _initialize() -> void:
	run.call_deferred()

func capture(name_value: String) -> void:
	await create_timer(0.25).timeout
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/m10-" + name_value + ".png")

func pilot() -> InputFrame:
	var frame := InputFrame.new()
	frame.movement = Vector2.RIGHT
	var x: float = ui.trial.course.player.position.x
	frame.jump_held = true
	if x > 540 and not jump_one:
		jump_one = true
		frame.jump_pressed = true
	if x > 3100 and not jump_two:
		jump_two = true
		frame.jump_pressed = true
	if x > 3330 and not dashed:
		dashed = true
		frame.dash_pressed = true
		frame.dash_direction = Vector2.RIGHT
	return frame

func run() -> void:
	folder = OS.get_cache_dir().path_join("pv-m10-render-" + PlayerProfileData.new_uuid())
	var main: Node = preload("res://core/bootstrap/main.tscn").instantiate()
	main.save_store = SaveStore.new(folder)
	root.add_child(main)
	await process_frame
	await process_frame
	for child: Node in main.get_children():
		if child is AppUI:
			ui = child
	TranslationServer.set_locale("ru")
	ui.show_menu()
	await capture("menu-ru")
	ui.show_new_game()
	await create_timer(0.25).timeout
	(ui.panel.find_child("TT_SOLO", true, false) as Button).grab_focus()
	var confirm := InputEventKey.new()
	confirm.physical_keycode = KEY_ENTER
	confirm.pressed = true
	Input.parse_input_event(confirm)
	await process_frame
	confirm = confirm.duplicate()
	confirm.pressed = false
	Input.parse_input_event(confirm)
	await create_timer(0.25).timeout
	if ui.screen != "maps":
		push_error("Solo button navigation failed")
		quit(1)
		return
	await capture("maps-ru")
	ui.start_map()
	await capture("hint-ru")
	ui.trial.dismiss_hint()
	await capture("countdown-ru")
	while ui.trial.phase != SoloTrial.Phase.RUN:
		await physics_frame
	await capture("go-ru")
	ui.trial.course.player.input_provider = pilot
	var budget: int = 1800
	while ui.trial.phase != SoloTrial.Phase.RESULT and budget > 0:
		await physics_frame
		budget -= 1
		if budget == 1680:
			await capture("run-ru")
	if ui.trial.phase != SoloTrial.Phase.RESULT:
		push_error("Motor-driven Solo course did not finish")
		quit(1)
		return
	await capture("result-ru")
	print("M10_DRIVEN_RUN ticks=%d deaths=%d" % [ui.trial.elapsed, ui.trial.deaths])
	TranslationServer.set_locale("en")
	ui.refresh()
	await capture("result-en")
	ui.trial.request_retry()
	await physics_frame
	await physics_frame
	ui.toggle_pause()
	await capture("pause-en")
	ui.show_menu()
	ui.input_layer.update_connection(42, true, "Xbox Controller")
	ui.input_layer._select_device("controller", 42)
	ui.start_map()
	await capture("hint-gamepad-en")
	ui.show_menu()
	main.input_preferences.flush()
	main.free()
	await process_frame
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	print("PROJECTVELOCITY_M10_RENDER_OK")
	quit()
