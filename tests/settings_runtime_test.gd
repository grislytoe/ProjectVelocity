extends SceneTree
## Run without --headless for native DisplayServer and GPU evidence. Isolated saves.

var failures: int = 0
var ui: AppUI
var main: Node
var folder: String
var render: bool = false

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func settle() -> void:
	await create_timer(0.3).timeout
	while ui.busy:
		await process_frame

func capture(tag: String) -> void:
	if render:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/m12-" + tag + ".png")

func press(action: String, pad: bool = false) -> void:
	var token: String = InputBindings.defaults("gamepad" if pad else "keyboard")[action][0]
	var event: InputEvent = InputBindings.event_for(token, 42 if pad else -1)
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()

func run() -> void:
	render = DisplayServer.get_name() != "headless"
	folder = OS.get_cache_dir().path_join("pv-m12-runtime-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated runtime store")
	store.data.onboarding_complete = true
	store.data.settings.audio.mutes.master = true
	store.data.settings.video.resolution = [1280, 720]
	var fixture_uuid: String = store.data.profile.uuid
	check(store.save(), "Muted native test fixture")
	main = preload("res://core/bootstrap/main.tscn").instantiate()
	main.save_store = store
	root.add_child(main)
	await process_frame
	await process_frame
	check(store.data.settings.video.resolution == [1280, 800] and store.data.profile.uuid == fixture_uuid,
		"Legacy low resolution upgrades to Steam Deck minimum without resetting profile")
	check(root.min_size == DisplayAdapter.MINIMUM, "Window resizing respects Steam Deck minimum")
	ui = main.get_children().filter(func(node: Node) -> bool: return node is AppUI)[0]
	await settle()
	ui.show_menu()
	await settle()
	ui.input_layer.update_connection(42, true, "Xbox")
	var session: SettingsSession = main.settings_session
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		for category: String in ["video", "audio", "controls", "accessibility"]:
			ui.settings_page.show_page(category)
			await settle()
			var focus: Control = root.gui_get_focus_owner()
			check(focus != null, "Page initial focus")
			print("M12_PAGE_FOCUS=", category, ":", focus.name if focus != null else "none")
			if focus != null:
				var scroll: ScrollContainer = ui.column.get_parent() as ScrollContainer
				check(scroll.get_global_rect().encloses(focus.get_global_rect()),
					"Initial focused setting is visible inside the scroll area")
				if focus.has_meta("settings_caption"):
					var caption: Control = focus.get_meta("settings_caption").get_ref()
					check(scroll.get_global_rect().encloses(caption.get_global_rect()), "Focused setting caption stays visible")
			await capture(category + "-" + locale)
			await press("ui_focus_next", true)
			check(root.gui_get_focus_owner() != null, "Pad traverses page")
			await press("ui_cancel")
			check(ui.screen == "settings" and not session.editing, "Back discards draft")
	for scale: float in [0.5, 1.0, 1.5, 2.0]:
		ui.settings_page.show_page("accessibility")
		session.draft.accessibility.ui_scale = scale
		session.draft.accessibility.text_size = 1.5
		check(session.apply(), "Scale commit")
		ui.settings_page.show_page("accessibility")
		await settle()
		var apply_button := ui.panel.find_child("SET_APPLY", true, false) as Button
		apply_button.grab_focus()
		await process_frame
		await process_frame
		check(apply_button.get_global_rect().size.x <= ui.panel.size.x, "Scaled Apply fits panel")
		check(ui.panel.get_global_rect().end.x <= root.get_visible_rect().size.x,
			"Extreme text and scale cannot expand panel beyond viewport")
		await capture("scale-" + str(scale))
		session.cancel()
	ui.settings_page.show_page("video")
	session.draft.accessibility.ui_scale = 1.0
	session.draft.accessibility.text_size = 1.0
	session.apply()
	if render:
		print("M12_NATIVE_SCREEN=", DisplayServer.screen_get_size())
		for unsupported: Vector2i in [Vector2i(640, 360), Vector2i(1280, 720), Vector2i(960, 1080)]:
			check(not session.adapter.supported(unsupported), "Reject sizes below Steam Deck minimum")
		var before: Dictionary = session.adapter.snapshot()
		var sizes: Array = session.adapter.choices()
		for size: Array in [[1680, 900], [1280, 1080]]:
			if session.adapter.supported(Vector2i(size[0], size[1])):
				sizes.append(size)
		for resolution: Array in sizes:
			var proposed: Dictionary = session.draft.video.duplicate(true)
			proposed.resolution = resolution
			proposed.window_mode = "windowed"
			check(session.adapter.apply(proposed), "Native window request")
			await settle()
			check(session.adapter.matches(proposed), "Native window actual size")
			check(root.get_visible_rect().size.is_equal_approx(Vector2(1920, 1080)), "Native aspect keeps competitive view")
			print("M12_NATIVE_WINDOW=", DisplayServer.window_get_size())
			if resolution == [1680, 900]:
				await capture("ultrawide")
		session.adapter.restore(before)
		for enabled: bool in [false, true]:
			session.draft.video.vsync = enabled
			check(session.apply(), "Native VSync save")
			check(DisplayServer.window_get_vsync_mode() == (DisplayServer.VSYNC_ENABLED if enabled else DisplayServer.VSYNC_DISABLED), "Native VSync readback")
		for mode: String in ["fullscreen", "borderless"]:
			ui.settings_page.show_page("video")
			await settle()
			session.draft.video.window_mode = mode
			session.draft.video.resolution = [1280, 800]
			ui.settings_page.apply()
			await settle()
			check(session.previewing, "Native preview stays active")
			if session.previewing:
				check(session.adapter.matches(session.draft.video), "Native fullscreen readback")
				check(main.settings_runtime.world.viewport.size == Vector2i(1280, 720), "Fullscreen uses selected render pixels")
				await capture("confirmation-" + mode)
				await press("ui_cancel", true)
				check(not session.previewing, "Pad reverts native modal")
			session.revert()
			session.adapter.restore(before)
		for mode: String in ["fullscreen", "borderless"]:
			ui.settings_page.show_page("video")
			session.draft.video.window_mode = mode
			session.draft.video.resolution = [1280, 800]
			ui.settings_page.apply()
			await settle()
			check(session.keep(), "Keep fullscreen resolution")
			await settle()
			ui.settings_page.show_page("video")
			await settle()
			var selector := ui.panel.find_child("SET_RESOLUTION", true, false) as OptionButton
			check(not selector.disabled, "Fullscreen resolution selector remains enabled")
			var modes := ui.panel.find_child("SET_WINDOW", true, false) as OptionButton
			modes.item_selected.emit(1 if mode == "fullscreen" else 2)
			check(session.draft.video.resolution == [1280, 800], "Mode selection preserves resolution")
			for resolution: Array in [[1600, 900], [1920, 1080]]:
				session.draft.video.resolution = resolution
				ui.settings_page.apply()
				await settle()
				check(session.previewing and session.adapter.matches(session.draft.video), "Same-mode resolution preview")
				check(main.settings_runtime.world.viewport.size == WorldPresentation.render_size(resolution), "GPU buffer fits selected resolution")
				check(root.get_visible_rect().size == Vector2(1920, 1080), "Fullscreen UI reference stays fixed")
				session.revert()
				await settle()
				check(main.settings_runtime.world.viewport.size == Vector2i(1280, 720), "Revert restores render resolution")
			var reload_store := SaveStore.new(folder)
			check(reload_store.open() and Vector2i(reload_store.data.settings.video.resolution[0], reload_store.data.settings.video.resolution[1]) == Vector2i(1280, 800)
				and reload_store.data.settings.video.window_mode == mode, "Only confirmed fullscreen resolution persists")
		# Restore a confirmed windowed baseline for the remaining input tests.
		ui.settings_page.show_page("video")
		session.draft.video.window_mode = "windowed"
		session.draft.video.resolution = [1280, 800]
		ui.settings_page.apply()
		await settle()
		check(session.keep(), "Confirm windowed baseline")
		await settle()
		ui.settings_page.show_page("video")
		await settle()
		session.draft.video.resolution = [1600, 900] if session.adapter.supported(Vector2i(1600, 900)) else [1280, 800]
		ui.settings_page.apply()
		await settle()
		if session.previewing:
			(ui.modal as ConfirmationDialog).get_ok_button().grab_focus()
			await press("ui_accept")
			check(not session.previewing and store.data.settings.video.resolution == session.draft.video.resolution, "Keyboard Keep native modal")
		else:
			check(false, "Native window confirmation exists")
		session.adapter.restore(before)
		ui.settings_page.show_page("video")
		await settle()
		session.draft.video.resolution = [1280, 800]
		ui.settings_page.apply()
		await settle()
		check(session.previewing, "Mouse test preview")
		if session.previewing:
			var dialog: DisplayConfirmation = ui.modal as DisplayConfirmation
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = Vector2(dialog.position) + dialog.get_cancel_button().get_global_rect().get_center()
			click.pressed = true
			root.push_input(click, true)
			await process_frame
			click = click.duplicate()
			click.pressed = false
			root.push_input(click, true)
			await settle()
			check(not session.previewing, "Mouse Revert native modal")
		session.revert()
		session.adapter.restore(before)
	session.cancel()
	ui.show_maps()
	await settle()
	for scale: float in [0.5, 1.0, 2.0]:
		session.begin()
		session.draft.accessibility.ui_scale = scale
		session.draft.accessibility.text_size = 1.5
		check(session.apply(), "HUD settings commit")
		session.cancel()
		ui.start_map()
		await settle()
		check(is_instance_valid(ui.trial), "Settings returns to Solo")
		var world: SubViewport = main.settings_runtime.world.viewport
		check(ui.trial.get_viewport() == world, "Solo renders through selected resolution viewport")
		check(world.get_visible_rect().size == Vector2(1920, 1080), "World logical view stays fixed")
		ui.trial.dismiss_hint()
		await settle()
		check(ui.hud.scale == Vector2.ONE * scale and ui.hud.get_theme_font_size("font_size") == 51,
			"HUD applies text size and UI scale")
		check(ui.hud.get_global_rect().end.x <= 1920 and ui.banner.get_global_rect().end.y <= 1080,
			"Scaled HUD and countdown stay in competitive frame")
		await capture("hud-scale-" + str(scale))
	# Actual world rendering changes pixel density without changing the camera or HUD.
	paused = true
	var world: SubViewport = main.settings_runtime.world.viewport
	var camera := world.get_camera_2d() as LocalPlayerCamera
	check(camera != null, "World viewport owns the local camera")
	var original_zoom: Vector2 = camera.zoom
	var original_center: Vector2 = camera.global_position
	for resolution: Array in [[1280, 800], [1600, 900], [1920, 1080]]:
		var proposed: Dictionary = store.data.settings.duplicate(true)
		proposed.video.resolution = resolution
		main.settings_runtime.apply(proposed)
		await process_frame
		camera.update_follow(true)
		check(camera.zoom.is_equal_approx(original_zoom) and camera.global_position.is_equal_approx(original_center),
			"Render resolution preserves camera framing")
		check(world.get_visible_rect().size == Vector2(1920, 1080), "Virtual world resolution remains fixed")
		if render:
			await RenderingServer.frame_post_draw
			check(world.get_texture().get_image().get_size() == WorldPresentation.render_size(resolution),
				"GPU image has the selected pixel dimensions")
			await capture("world-" + str(resolution[0]) + "x" + str(resolution[1]))
	main.settings_runtime.apply(store.data.settings)
	paused = false
	ui.show_menu()
	await settle()
	main.queue_free()
	await process_frame
	await process_frame
	for filename: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(filename))
	DirAccess.remove_absolute(folder)
	if failures == 0:
		print("PROJECTVELOCITY_M12_RUNTIME_OK native=", render)
	quit(0 if failures == 0 else 1)
