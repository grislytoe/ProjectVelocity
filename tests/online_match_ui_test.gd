extends SceneTree
## M21 RU/EN final-result presentation and focus/navigation contract.

var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("M21 UI: " + message)

func run() -> void:
	var layer := InputLayer.new()
	var session := NetworkSession.new()
	session.host = true
	session.series.configure(MapCatalog.training(), 2)
	session.series.score = [1, 1]
	session.series.best_times = [120, 180]
	session.series.round_index = 2
	session.series.round_results = [
		[1, 1, session.series.settings_identity, [1, 2], 1, [120, -1], [1, 2], [7, 5],
			[[0, 1, 2, 3, 4, 5, 6], [0, 1, 2, 3, 4]], 1920, 1],
		[2, 2, session.series.settings_identity, [1, 2], 2, [-1, 180], [2, 1], [5, 7],
			[[0, 1, 2, 3, 4], [0, 1, 2, 3, 4, 5, 6]], 2100, 1],
	]
	session.series.final_winner = 0
	session.series.phase = OnlineSeries.Phase.FINAL_SERIES_RESULTS
	var overlay := OnlineMatchOverlay.new()
	root.add_child(overlay)
	overlay.bind(session, layer)
	overlay.refresh()
	await process_frame
	check(overlay.visible and overlay.play_again_button.visible and overlay.lobby_button.visible
		and overlay.menu_button.visible, "all final actions visible")
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		overlay.refresh()
		check(not overlay.result_label.text.is_empty() and overlay.result_label.text.contains("00:02.000")
			and overlay.result_label.text.contains("00:03.000"), "%s result history and best times" % locale)
		check(overlay.phase_label.text == tr("M21_SERIES_RESULTS"), "%s localized heading" % locale)
	for button: Button in [overlay.play_again_button, overlay.lobby_button, overlay.menu_button]:
		check(button.focus_mode == Control.FOCUS_ALL and not button.text.is_empty(),
			"keyboard/controller focus on " + button.name)
	overlay.play_again_button.grab_focus()
	await process_frame
	check(root.gui_get_focus_owner() == overlay.play_again_button, "keyboard focus restoration")
	var routes: Array[String] = []
	overlay.route_requested.connect(func(route: String) -> void: routes.append(route))
	session.host = false
	overlay.lobby_button.pressed.emit()
	overlay.menu_button.pressed.emit()
	check(routes == ["lobby", "menu"], "mouse/button routes return Lobby and Main Menu")
	# Existing abstraction changes glyph family without rebuilding the result screen.
	layer.connected_pads[7] = "Test Pad"
	layer._select_device("controller", 7)
	check(layer.last_device == "controller" and not layer.prompt("jump").get("label", "").is_empty(),
		"controller prompts selected")
	layer._select_device("keyboard_mouse", -1)
	check(layer.last_device == "keyboard_mouse" and not layer.prompt("jump").get("label", "").is_empty(),
		"keyboard prompts selected")
	overlay.queue_free(); layer.free(); session.barrier.free(); session.free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PROJECTVELOCITY_M21_UI_OK")
	quit(0 if failures == 0 else 1)
