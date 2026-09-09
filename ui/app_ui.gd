class_name AppUI
extends TrialUI
## Front-end composition. Inherits the established Solo/pause/result presentation loop.

var edit: ProfileEdit
var nickname: LineEdit
var feedback: Label
var preview: RobotPreview
var save_button: Button
var prompt: Label
var busy: bool = false
var transition: Tween
var generation: int = 0
var modal: Window
var remembered: Dictionary = {}
var form_origin: String = "menu"
var splash_elapsed: float = 0.0
var settings: SettingsSession
var settings_page: SettingsPage

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_layer.prompts_changed.connect(_prompts_changed)
	if settings != null:
		settings_page = SettingsPage.new(self)
		settings.preview_finished.connect(_display_finished)
	show_splash()

func _panel(title: String) -> void:
	generation += 1
	if transition != null:
		transition.kill()
	busy = true
	if is_instance_valid(modal):
		modal.queue_free()
	if is_instance_valid(panel):
		panel.free()
	panel = PanelContainer.new()
	panel.theme = IndustrialTheme.create()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 96
	panel.offset_right = -96
	panel.offset_top = 72
	panel.offset_bottom = -72
	add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	panel.add_child(margin)
	var layout := VBoxContainer.new()
	margin.add_child(layout)
	var eyebrow := Label.new()
	eyebrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	eyebrow.text = "PROJECT / VELOCITY    •    " + BuildInfo.label()
	eyebrow.add_theme_color_override("font_color", Color("73e7d2"))
	eyebrow.add_theme_font_size_override("font_size", 20)
	layout.add_child(eyebrow)
	var heading := Label.new()
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.text = tr(title)
	heading.add_theme_font_size_override("font_size", 48)
	layout.add_child(heading)
	layout.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.follow_focus = true
	layout.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	prompt = Label.new()
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(prompt)
	_update_footer()
	panel.modulate.a = 0.0
	transition = create_tween()
	transition.tween_property(panel, "modulate:a", 1.0, 0.2)
	transition.tween_callback(_finish_transition.bind(generation))
	_wire_focus.call_deferred(generation)

func _finish_transition(token: int) -> void:
	if token != generation:
		return
	busy = false
	input_layer.clear_transient_state()
	_wire_focus(token)
	_reveal_focus.call_deferred(token)

func _reveal_focus(token: int) -> void:
	if token != generation:
		return
	var owner: Control = get_viewport().gui_get_focus_owner()
	if owner == null:
		return
	var ancestor: Node = owner.get_parent()
	while ancestor != null and ancestor != panel:
		if ancestor is ScrollContainer:
			if owner.has_meta("settings_caption"):
				var caption: Control = owner.get_meta("settings_caption").get_ref() as Control
				if caption != null:
					ancestor.ensure_control_visible(caption)
			ancestor.ensure_control_visible(owner)
			return
		ancestor = ancestor.get_parent()

func button(key: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = tr(key)
	item.name = key.validate_node_name()
	item.custom_minimum_size.y = 58
	item.alignment = HORIZONTAL_ALIGNMENT_LEFT
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.pressed.connect(func() -> void:
		if busy or is_instance_valid(modal):
			return
		remembered[screen] = item.name
		if settings != null:
			settings.runtime.cue("UI")
		busy = true
		_activate.call_deferred(callback, generation))
	column.add_child(item)
	return item

func _activate(callback: Callable, token: int) -> void:
	if token != generation:
		return
	busy = false
	input_layer.clear_transient_state()
	callback.call()

func _controls(node: Node, output: Array[Control]) -> void:
	for child: Node in node.get_children():
		if child is Control and child.is_visible_in_tree() and child.focus_mode == Control.FOCUS_ALL:
			if not child is BaseButton or not child.disabled:
				output.append(child)
		_controls(child, output)

func _wire_focus(token: int) -> void:
	if token != generation or not is_instance_valid(panel):
		return
	_scale_controls(panel)
	var items: Array[Control] = []
	_controls(panel, items)
	for index: int in items.size():
		var before: Control = items[posmod(index - 1, items.size())]
		var after: Control = items[(index + 1) % items.size()]
		items[index].focus_previous = items[index].get_path_to(before)
		items[index].focus_next = items[index].get_path_to(after)
		items[index].focus_neighbor_top = items[index].get_path_to(before)
		items[index].focus_neighbor_bottom = items[index].get_path_to(after)
		if items[index] is Button:
			items[index].focus_neighbor_left = items[index].get_path_to(before)
			items[index].focus_neighbor_right = items[index].get_path_to(after)
	var owner: Control = get_viewport().gui_get_focus_owner()
	if owner != null and items.has(owner):
		return
	for item: Control in items:
		if item.name == remembered.get(screen, ""):
			item.grab_focus()
			return
	if not items.is_empty():
		items[0].grab_focus()

func _scale_controls(node: Node) -> void:
	var factor: float = float(SettingsRuntime.access("ui_scale", 1.0))
	var text_factor: float = factor * float(SettingsRuntime.access("text_size", 1.0))
	if node is Control and not node.has_meta("settings_scaled"):
		node.set_meta("settings_scaled", true)
		if node is Label or node is Button or node is LineEdit:
			var base: int = node.get_theme_font_size("font_size")
			node.add_theme_font_size_override("font_size", maxi(12, roundi(base * text_factor)))
		if node is BaseButton:
			node.custom_minimum_size.y = maxf(36, node.custom_minimum_size.y * factor)
	for child: Node in node.get_children():
		_scale_controls(child)

func _update_footer() -> void:
	if is_instance_valid(prompt):
		prompt.text = tr("UI_NAV") % [input_layer.prompt("ui_accept").get("label", ""),
			input_layer.prompt("ui_cancel").get("label", ""), input_layer.prompt("ui_focus_next").get("label", "")]

func show_splash() -> void:
	screen = "splash"
	_panel("APP_TITLE")
	label(tr("UI_SPLASH"), 30)
	_add_preview(store.data.profile)
	button("UI_CONTINUE", _after_splash)
	splash_elapsed = 0.0

func _after_splash() -> void:
	if store.data.onboarding_complete:
		show_menu()
	else:
		edit = ProfileEdit.new(store)
		show_language()

func show_language() -> void:
	screen = "language"
	_panel("UI_LANGUAGE")
	label(tr("UI_WELCOME"))
	button("UI_ENGLISH", _choose_language.bind("en"))
	button("UI_RUSSIAN", _choose_language.bind("ru"))
	if not store.notification_key.is_empty():
		label(tr(store.notification_key))

func _choose_language(locale: String) -> void:
	edit.draft.language = locale
	TranslationServer.set_locale(locale)
	show_profile(true)

func show_menu() -> void:
	_leave()
	screen = "menu"
	_panel("UI_MAIN_MENU")
	var header: Button = button("UI_PROFILE", _open_profile)
	header.text = tr("UI_PROFILE") + "  /  " + str(store.data.profile.nickname)
	var row := HBoxContainer.new()
	column.add_child(row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(identity)
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(actions)
	column = identity
	_add_preview(store.data.profile, 380)
	label(tr("UI_SPLASH"), 22)
	column = actions
	button("UI_NEW_GAME", show_new_game)
	button("UI_CUSTOMIZATION", _open_customization)
	button("UI_SETTINGS", show_settings)
	button("UI_EDITOR", show_editor)
	button("TT_QUIT", _quit_dialog)
	if not store.notification_key.is_empty():
		label(tr(store.notification_key), 20)

func show_new_game() -> void:
	screen = "new_game"
	_panel("UI_NEW_GAME")
	label(tr("UI_SOLO_DESCRIPTION"), 30)
	button("TT_SOLO", show_maps)
	button("UI_ONLINE", show_online)
	button("UI_BACK", show_menu)

func show_online() -> void:
	screen = "online"
	_panel("UI_ONLINE")
	label(tr("UI_IN_DEVELOPMENT"), 34)
	for key: String in ["UI_CREATE_LOBBY", "UI_JOIN_LOBBY"]:
		var item: Button = button(key, Callable())
		item.disabled = true
		item.focus_mode = Control.FOCUS_NONE
	button("UI_BACK", show_new_game)

func show_maps() -> void:
	_leave()
	screen = "maps"
	_panel("TT_SELECT")
	var definition := TrialMapDefinition.new()
	var map_preview := CircuitPreview.new()
	column.add_child(map_preview)
	map_preview.custom_minimum_size.y = 160
	label(tr(definition.name_key), 32)
	label(tr(definition.description_key))
	label(tr("UI_DIFFICULTY") % tr(definition.difficulty_key), 22)
	var best: Dictionary = TrialRecords.new(store, definition).best()
	label(tr("TT_PB") % ("—" if best.is_empty() else TrialRecord.format_time(int(best.total))))
	button("TT_MAP", start_map)
	button("UI_BACK", show_new_game)
	label(tr("UI_MAP_METADATA") % [definition.map_id, definition.map_version], 20)
	label(tr("UI_MAP_AVAILABILITY"), 20)

func show_settings() -> void:
	screen = "settings"
	_panel("UI_SETTINGS")
	button("TT_CONTROLS", show_controls)
	button("UI_LANGUAGE", _open_profile)
	for key: String in ["UI_VIDEO", "UI_AUDIO", "UI_ACCESSIBILITY"]:
		button(key, settings_page.show_page.bind(key.trim_prefix("UI_").to_lower()))
	button("UI_BACK", show_menu)

func show_editor() -> void:
	screen = "editor"
	_panel("UI_EDITOR")
	label(tr("UI_IN_DEVELOPMENT"), 48)
	label(tr("UI_EDITOR_DESCRIPTION"), 28)
	button("UI_BACK", show_menu)

func show_controls() -> void:
	settings_page.show_page("controls")

func _display_finished(kept: bool) -> void:
	_finish_display.call_deferred(kept)

func _finish_display(kept: bool) -> void:
	if is_instance_valid(modal):
		modal.hide()
		modal.queue_free()
	await get_tree().process_frame
	settings_page.show_page(settings_page.category)
	if settings.error_key.is_empty():
		settings_page.feedback.text = tr("SET_SAVED" if kept else "SET_REVERTED")

func _open_profile() -> void:
	form_origin = screen
	edit = ProfileEdit.new(store)
	show_profile(false)

func show_profile(onboarding: bool = false) -> void:
	screen = "onboarding" if onboarding else "profile"
	_panel("UI_SETUP_PROFILE" if onboarding else "UI_PROFILE")
	label(tr("UI_NAME_RULES"), 22)
	nickname = LineEdit.new()
	nickname.name = "Nickname"
	nickname.text = edit.draft.nickname
	nickname.max_length = 15
	nickname.custom_minimum_size.y = 60
	nickname.virtual_keyboard_enabled = true
	column.add_child(nickname)
	button("UI_KEYBOARD", _open_keyboard)
	var language_button: Button = button("UI_LANGUAGE", _draft_language)
	language_button.text += "  /  " + tr("UI_RUSSIAN" if edit.draft.language == "ru" else "UI_ENGLISH")
	label(tr("UI_IDENTITY") % store.data.profile.uuid, 20)
	feedback = label("", 22)
	save_button = button("UI_CONTINUE" if onboarding else "UI_SAVE", _save_profile)
	button("UI_BACK" if onboarding else "UI_CANCEL", _cancel_edit)
	nickname.text_changed.connect(func(value: String) -> void:
		edit.draft.nickname = value
		_validate_name())
	_validate_name()

func _validate_name() -> void:
	var valid: bool = PlayerProfileData.valid_nickname(nickname.text)
	save_button.disabled = not valid
	save_button.focus_mode = Control.FOCUS_ALL if valid else Control.FOCUS_NONE
	feedback.text = "" if valid else tr("UI_INVALID_NAME")
	_wire_focus.call_deferred(generation)

func _draft_language() -> void:
	edit.draft.language = "ru" if edit.draft.language == "en" else "en"
	TranslationServer.set_locale(edit.draft.language)
	show_profile(screen == "onboarding")

func toggle_language() -> void:
	# Compatibility entry point: retain the same transaction and failure reporting.
	_open_profile()
	_draft_language()

func _save_profile() -> void:
	if not edit.commit(screen == "onboarding"):
		feedback.text = tr("TT_SAVE_FAILED")
		return
	edit = null
	show_menu()

func _cancel_edit() -> void:
	if screen == "onboarding":
		show_language()
		return
	TranslationServer.set_locale(store.data.profile.language)
	edit = null
	if form_origin == "settings":
		show_settings()
	else:
		show_menu()

func _open_keyboard() -> void:
	var keyboard := NameKeyboard.new()
	keyboard.value = nickname.text
	keyboard.russian = TranslationServer.get_locale().begins_with("ru")
	keyboard.accepted.connect(func(value: String) -> void:
		nickname.text = value
		edit.draft.nickname = value
		_validate_name())
	_present_modal(keyboard)

func _present_modal(window: Window) -> void:
	var previous: Control = get_viewport().gui_get_focus_owner()
	var previous_weak: WeakRef = weakref(previous)
	modal = window
	add_child(modal)
	modal.tree_exited.connect(func() -> void:
		input_layer.clear_transient_state()
		var old_focus: Control = previous_weak.get_ref() as Control
		if is_instance_valid(old_focus):
			old_focus.grab_focus.call_deferred())
	modal.popup_centered()

func _quit_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = tr("TT_QUIT")
	dialog.dialog_text = tr("UI_QUIT_CONFIRM")
	dialog.ok_button_text = tr("TT_QUIT")
	dialog.cancel_button_text = tr("UI_CANCEL")
	dialog.theme = IndustrialTheme.create()
	dialog.exclusive = true
	dialog.confirmed.connect(func() -> void: get_tree().quit())
	dialog.canceled.connect(dialog.queue_free)
	_present_modal(dialog)
	dialog.get_cancel_button().grab_focus()

func _add_preview(profile: Dictionary, height: float = 260) -> void:
	preview = RobotPreview.new()
	preview.profile = profile
	column.add_child(preview)
	preview.custom_minimum_size.y = height

func _open_customization() -> void:
	form_origin = "menu"
	edit = ProfileEdit.new(store)
	show_customization()

func show_customization() -> void:
	screen = "customization"
	_panel("UI_CUSTOMIZATION")
	_add_preview(edit.draft, 220)
	label(tr("UI_COLOR_HELP"), 20)
	for field: String in ["body_color", "accent_color"]:
		var row := HBoxContainer.new()
		column.add_child(row)
		var caption := Label.new()
		caption.text = tr("UI_BODY" if field == "body_color" else "UI_ACCENT")
		caption.custom_minimum_size.x = 230
		row.add_child(caption)
		var color: Color = Color.html(edit.draft[field])
		for channel: int in 3:
			var channel_column := VBoxContainer.new()
			channel_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(channel_column)
			var channel_label := Label.new()
			channel_column.add_child(channel_label)
			var spin := HSlider.new()
			spin.min_value = 0
			spin.max_value = 255
			spin.step = 1
			spin.value = roundi(color[channel] * 255)
			channel_label.text = ["R", "G", "B"][channel] + "  " + str(int(spin.value))
			spin.custom_minimum_size = Vector2(180, 40)
			spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			channel_column.add_child(spin)
			spin.value_changed.connect(func(value: float) -> void:
				channel_label.text = ["R", "G", "B"][channel] + "  " + str(int(value))
				var proposed: Color = Color.html(edit.draft[field])
				proposed[channel] = value / 255.0
				edit.draft[field] = proposed.to_html()
				preview.update_profile(edit.draft))
	label(tr("UI_COSMETICS_UNAVAILABLE"), 20)
	feedback = label("", 22)
	button("UI_SAVE", _save_profile)
	button("UI_CANCEL", _cancel_edit)

func start_map() -> void:
	input_layer.quarantine_gameplay_entry()
	super.start_map()
	var font_scale: float = float(SettingsRuntime.access("text_size", 1.0))
	var ui_scale: float = float(SettingsRuntime.access("ui_scale", 1.0))
	for item: Label in [hud, banner, status]:
		item.add_theme_font_size_override("font_size", roundi(item.get_theme_font_size("font_size") * font_scale))
		item.scale = Vector2.ONE * ui_scale
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.size.x = 900 / ui_scale
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.size.x = 900 / ui_scale
	banner.position.x = (1920 - banner.size.x * ui_scale) / 2
	_apply_player_profile()
	trial.changed.connect(_apply_player_profile.call_deferred)

func _apply_player_profile() -> void:
	if is_instance_valid(trial):
		_apply_to_robots(trial.course)

func _apply_to_robots(node: Node) -> void:
	if node is PlayerPlaceholder:
		node.apply_profile(PlayerProfileData.from_dictionary(store.data.profile))
	for child: Node in node.get_children():
		_apply_to_robots(child)

func _prompts_changed() -> void:
	# Device changes update prompts without rebuilding forms or stealing focus.
	_update_footer()
	if settings_page != null:
		settings_page.refresh_prompts()
	if screen == "controls" and input_layer.last_rebind_result.is_empty():
		for action: String in ["jump", "dash", "restart", "pause"]:
			var item: Button = panel.find_child("TT_BIND_" + action.to_upper(), true, false) as Button
			if item != null:
				item.text = tr("TT_BIND_" + action.to_upper()) + "  ·  " + str(input_layer.prompt(action).get("label", ""))
		return
	if is_instance_valid(trial) and trial.phase == SoloTrial.Phase.HINT:
		refresh.call_deferred()

func _process(delta: float) -> void:
	super._process(delta)
	if settings_page != null and screen.begins_with("settings_"):
		settings_page.poll()
		if settings.previewing and is_instance_valid(modal) and modal is ConfirmationDialog:
			modal.dialog_text = tr("SET_CONFIRM_HELP") + "\n" + str(ceili(settings.remaining))
	for item: Label in [hud, banner, status]:
		if is_instance_valid(item):
			item.visible = not is_instance_valid(panel)
			item.modulate.a = float(SettingsRuntime.access("hud_opacity", 1.0))
	if is_instance_valid(hud) and is_instance_valid(status) and is_instance_valid(banner):
		status.position.y = hud.position.y + hud.size.y * hud.scale.y + 16
		banner.position.y = maxf(155, status.position.y + status.size.y * status.scale.y + 24)
	if screen == "splash":
		splash_elapsed += delta
		if splash_elapsed > 1.2 and not busy:
			_after_splash()

func _input(event: InputEvent) -> void:
	if is_instance_valid(modal):
		if modal is DisplayConfirmation and modal.route(event):
			get_viewport().set_input_as_handled()
		return
	if settings_page != null and settings_page.capture:
		if event.is_action_pressed("ui_cancel"):
			input_layer.cancel_rebind()
			get_viewport().set_input_as_handled()
		return
	if busy:
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
			get_viewport().set_input_as_handled()
		return
	if screen == "controls" and not input_layer._capture_action.is_empty():
		if event.is_action_pressed("ui_cancel"):
			input_layer.cancel_rebind()
			show_controls.call_deferred()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_back.call_deferred()
		return
	super._input(event)

func _back() -> void:
	if busy:
		return
	if screen.begins_with("settings_"):
		settings_page.cancel()
		return
	match screen:
		"splash": _after_splash()
		"menu": _quit_dialog()
		"language": pass
		"profile", "onboarding", "customization": _cancel_edit()
		"online", "maps": show_new_game()
		"controls": show_settings()
		"trial":
			if trial.phase == SoloTrial.Phase.RESULT:
				show_maps()
			else:
				toggle_pause()
		_: show_menu()
