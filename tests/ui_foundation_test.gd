extends SceneTree
## Isolated integration tests. Input events exercise Godot GUI; no physical pad claim.

var failures: int = 0
var folder: String
var main: Node
var ui: AppUI
var capture_enabled: bool = false
var capture_suffix: String = ""

class DeniedStore extends SaveStore:
	func _replace(_staged: String, _target: String) -> bool:
		return false

class HeldInput extends InputLayer:
	var held: bool = true
	func _hardware_held(_event: InputEvent) -> bool:
		return held

func _initialize() -> void:
	run.call_deferred()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle() -> void:
	await create_timer(0.25).timeout
	await process_frame
	# GPU frames can be slower than wall-clock timers. Wait for the actual UI boundary.
	var budget: int = 120
	while is_instance_valid(ui) and ui.busy and budget > 0:
		await process_frame
		budget -= 1
	check(budget > 0, "Transition releases navigation")

func action(name_value: String, joy: bool = false) -> void:
	var tokens: Array = InputBindings.defaults("gamepad" if joy else "keyboard")[name_value]
	var event: InputEvent = InputBindings.event_for(tokens[0], 42 if joy else -1)
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await settle()

func find_button(key: String) -> Button:
	return ui.panel.find_child(key.validate_node_name(), true, false) as Button

func activate(key: String, joy: bool = false) -> void:
	var item: Button = find_button(key)
	check(item != null, "Button exists: " + key)
	if item != null:
		item.grab_focus()
		await action("ui_accept", joy)

func mouse(key: String) -> void:
	var item: Button = find_button(key)
	check(item != null, "Mouse target exists: " + key)
	if item == null:
		return
	item.grab_focus()
	await process_frame
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = item.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await settle()

func capture(tag: String) -> void:
	if not capture_enabled:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/m11-" + tag + capture_suffix + ".png")

func edit_name(value: String) -> void:
	ui.nickname.text = value
	ui.nickname.text_changed.emit(value)
	await process_frame

func run() -> void:
	capture_enabled = OS.get_cmdline_user_args().has("--render-capture")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-tag="):
			capture_suffix = "-" + argument.trim_prefix("--capture-tag=").validate_filename()
	folder = OS.get_cache_dir().path_join("pv-m11-test-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Create isolated save")
	var identity: String = store.data.profile.uuid
	check(not store.data.onboarding_complete, "First-run explicit incomplete marker")
	var legacy: Dictionary = store.data.duplicate(true)
	legacy.save_version = 3
	legacy.erase("onboarding_complete")
	var migrated: Dictionary = SaveSchema.decode(legacy)
	check(migrated.status == "valid" and not migrated.data.onboarding_complete,
		"v3 migration requires onboarding")
	check(migrated.data.profile.uuid == identity, "Migration preserves UUID")
	var draft := ProfileEdit.new(store)
	store.data.time_trial_records = {"legacy": {"best_time_ms": 123}}
	store.data.settings.audio.music = 0.3
	draft.draft.nickname = "Пилот_1"
	check(draft.commit(), "Valid Cyrillic save")
	check(store.data.time_trial_records.legacy.best_time_ms == 123 and
		is_equal_approx(store.data.settings.audio.music, 0.3), "Preserve other sections")
	for bad: String in ["ab", "                ", "😀pilot", "A\u0483B", "ééé", "aaa\n"]:
		draft.draft.nickname = bad
		check(not draft.commit(), "Reject invalid nickname")
	draft.draft.nickname = "Other Pilot"
	var previous: Dictionary = store.data.duplicate(true)
	store.read_only = true
	check(not draft.commit(true) and store.data == previous, "Save failure rolls back marker and fields")
	store.read_only = false
	var disk_before: String = FileAccess.get_file_as_string(folder.path_join("save.json"))
	var denied := DeniedStore.new(folder)
	denied.data = store.data.duplicate(true)
	var denied_edit := ProfileEdit.new(denied)
	denied_edit.draft.nickname = "Write failure"
	check(not denied_edit.commit(true), "Actual replace failure reported")
	check(denied.data == store.data and not denied.data.onboarding_complete,
		"Actual IO failure restores in-memory profile and marker")
	check(FileAccess.get_file_as_string(folder.path_join("save.json")) == disk_before,
		"Actual IO failure retains good primary")
	main = preload("res://core/bootstrap/main.tscn").instantiate()
	main.save_store = store
	root.add_child(main)
	await process_frame
	await process_frame
	ui = main.get_children().filter(func(node: Node) -> bool: return node is AppUI)[0]
	check(ui.screen == "splash", "F5 starts splash")
	await settle()
	await capture("splash-en")
	await activate("UI_CONTINUE")
	check(ui.screen == "language", "Splash opens language")
	await capture("language-en")
	await activate("UI_RUSSIAN")
	check(ui.screen == "onboarding", "Language precedes nickname")
	await capture("onboarding-ru")
	await edit_name("ab")
	check(ui.save_button.disabled, "Invalid form disables save")
	await edit_name("Пилот 42")
	ui.input_layer.update_connection(42, true, "Xbox Controller")
	await activate("UI_KEYBOARD", true)
	check(is_instance_valid(ui.modal), "Controller opens exclusive text entry")
	await capture("keyboard-ru")
	var keyboard: NameKeyboard = ui.modal
	keyboard.field.text = "Controller 42"
	keyboard._accept()
	await settle()
	check(ui.nickname.text == "Controller 42", "Keyboard applies to draft")
	check(root.gui_get_focus_owner() == find_button("UI_KEYBOARD"), "Modal restores focus")
	await activate("UI_KEYBOARD", true)
	keyboard = ui.modal
	var modal_event := InputEventJoypadButton.new()
	modal_event.device = 42
	modal_event.button_index = JOY_BUTTON_A
	modal_event.pressed = true
	keyboard.push_input(modal_event, true)
	await process_frame
	modal_event = modal_event.duplicate()
	modal_event.pressed = false
	keyboard.push_input(modal_event, true)
	await process_frame
	check(keyboard.field.text.ends_with("А"), "Controller GUI enters a character")
	modal_event.button_index = JOY_BUTTON_B
	modal_event.pressed = true
	keyboard.push_input(modal_event, true)
	await settle()
	check(not is_instance_valid(ui.modal) and ui.nickname.text == "Controller 42",
		"Controller Back cancels keyboard draft")
	await activate("UI_CONTINUE", true)
	check(ui.screen == "menu" and store.data.onboarding_complete, "Onboarding persisted")
	check(store.data.profile.uuid == identity, "Name never changes UUID")
	var reopened := SaveStore.new(folder)
	check(reopened.open() and reopened.data.onboarding_complete, "Relaunch marker retained")
	await capture("menu-ru")
	await activate("UI_PROFILE")
	await edit_name("Unsaved")
	await action("ui_cancel")
	check(store.data.profile.nickname == "Controller 42", "Cancel discards edits")
	check(root.gui_get_focus_owner() == find_button("UI_PROFILE"), "Profile return focus")
	await activate("UI_PROFILE", true)
	await edit_name("Saved Pilot")
	store.read_only = true
	await activate("UI_SAVE", true)
	check(ui.screen == "profile" and ui.feedback.text == ui.tr("TT_SAVE_FAILED"), "UI reports save failure")
	check(store.data.profile.nickname == "Controller 42", "Failed UI save leaves profile")
	store.read_only = false
	await activate("UI_SAVE")
	check(store.data.profile.nickname == "Saved Pilot", "Retry save succeeds")
	await activate("UI_CUSTOMIZATION", true)
	var sliders: Array[Control] = []
	ui._controls(ui.panel, sliders)
	var slider: HSlider
	for control: Control in sliders:
		if control is HSlider:
			slider = control
			break
	check(slider != null, "Colors have focusable slider")
	var old_color: String = ui.edit.draft.body_color
	slider.grab_focus()
	await action("ui_right", true)
	check(ui.edit.draft.body_color != old_color, "Controller adjusts color")
	check(ui.preview.robot.appearance.body_color.to_html() == ui.edit.draft.body_color, "Live M4 preview")
	await capture("customization-ru")
	await activate("UI_SAVE", true)
	await activate("UI_NEW_GAME", true)
	await activate("TT_SOLO", true)
	check(ui.screen == "maps", "New Game Solo maps")
	await capture("maps-ru")
	await activate("TT_MAP", true)
	check(is_instance_valid(ui.trial), "Map launches real Solo")
	check(ui.trial.course.player.find_child("Presentation", true, false) != null, "Gameplay presentation exists")
	var robot: PlayerPlaceholder = ui.trial.course.player.find_child("Presentation", true, false)
	check(robot.appearance.body_color.to_html() == store.data.profile.body_color,
		"Saved customization reaches gameplay")
	await capture("hint-ru")
	await activate("TT_READY")
	await capture("countdown-ru")
	await action("ui_cancel")
	check(paused, "Back pauses Solo")
	var ticks: int = ui.trial.elapsed
	await settle()
	check(ui.trial.elapsed == ticks and ui.trial.valid, "Pause freezes and remains eligible")
	await capture("pause-ru")
	await activate("TT_SELECT")
	check(not paused and ui.trial == null and ui.screen == "maps", "Pause map round trip")
	for locale: String in ["en", "ru"]:
		store.data.profile.language = locale
		check(store.save(), "Persist capture locale so Cancel restores the correct language")
		TranslationServer.set_locale(locale)
		ui.show_splash()
		await settle()
		await capture("splash-" + locale)
		ui.edit = ProfileEdit.new(store)
		ui.show_language()
		await settle()
		await capture("language-" + locale)
		ui.show_profile(true)
		await settle()
		await capture("onboarding-" + locale)
		await activate("UI_KEYBOARD")
		await capture("keyboard-" + locale)
		ui.modal.queue_free()
		await settle()
		ui.show_menu()
		await settle()
		await capture("menu-" + locale)
		await mouse("UI_EDITOR")
		check(ui.screen == "editor", "Mouse editor navigation")
		await capture("editor-" + locale)
		await action("ui_cancel", true)
		await activate("UI_SETTINGS")
		await capture("settings-" + locale)
		check(find_button("UI_VIDEO").disabled, "Unavailable settings disabled")
		await action("ui_focus_next")
		check(root.gui_get_focus_owner() != find_button("UI_VIDEO"), "Disabled button skipped")
		await activate("TT_CONTROLS")
		await capture("controls-" + locale)
		await action("ui_cancel")
		await action("ui_cancel")
		await activate("UI_PROFILE")
		await capture("profile-" + locale)
		await action("ui_cancel")
		await activate("UI_CUSTOMIZATION")
		await capture("customization-" + locale)
		await action("ui_cancel")
		await activate("UI_NEW_GAME")
		await capture("new-game-" + locale)
		await activate("UI_ONLINE")
		await capture("online-" + locale)
		await action("ui_cancel")
		await activate("TT_SOLO")
		await capture("maps-" + locale)
		await action("ui_cancel")
		await action("ui_cancel")
		await activate("TT_QUIT")
		check(is_instance_valid(ui.modal), "Quit confirmation captures focus")
		ui.modal.queue_free()
		await settle()
	var count: int = main.get_child_count()
	var ui_count: int = ui.get_child_count()
	var connections: int = ui.input_layer.prompts_changed.get_connections().size()
	for index: int in 12:
		ui.show_editor()
		ui.show_menu()
	await settle()
	check(main.get_child_count() == count, "Repeated transitions keep stable ownership")
	check(ui.get_child_count() == ui_count and ui.input_layer.prompts_changed.get_connections().size() == connections,
		"Repeated screens retain no panels or prompt connections")
	ui.show_new_game()
	find_button("TT_SOLO").pressed.emit()
	await process_frame
	check(ui.screen == "new_game", "Transition ignores repeated activation")
	await settle()
	main.input_preferences.flush()
	main.free()
	await process_frame
	var gated := HeldInput.new()
	gated.watch_hardware = false
	root.add_child(gated)
	gated.quarantine_gameplay_entry()
	Input.action_press(gated.action_name("move_left"))
	Input.action_press(gated.action_name("jump"))
	check(gated.sample().movement == Vector2.ZERO and not gated.sample().jump_held,
		"Entry release gate blocks held movement and jump")
	gated.held = false
	check(gated.sample().movement == Vector2.ZERO, "Release gate clears stale action state")
	Input.action_press(gated.action_name("move_left"))
	check(gated.sample().movement.x < 0, "Fresh input works after release")
	gated.free()
	main = preload("res://core/bootstrap/main.tscn").instantiate()
	main.save_store = SaveStore.new(folder)
	root.add_child(main)
	await create_timer(1.6).timeout
	ui = main.get_children().filter(func(node: Node) -> bool: return node is AppUI)[0]
	check(ui.screen == "menu", "Actual relaunch skips completed onboarding")
	check(main.save_store.data.profile.uuid == identity, "Actual relaunch identity stable")
	main.input_preferences.flush()
	main.free()
	await process_frame
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	if failures == 0:
		print("PROJECTVELOCITY_M11_OK")
	quit(0 if failures == 0 else 1)
