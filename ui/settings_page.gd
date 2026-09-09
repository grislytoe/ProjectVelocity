class_name SettingsPage
extends RefCounted
## Small form builder; transactions and engine application live outside the UI.

var ui: AppUI
var session: SettingsSession
var category: String = "video"
var profile: String = "keyboard"
var feedback: Label
var capture: bool = false

func _init(owner: AppUI) -> void:
	ui = owner
	session = ui.settings

func show_page(group: String) -> void:
	category = group
	session.begin()
	ui.screen = "settings_" + group
	ui._panel("UI_" + group.to_upper() if group != "controls" else "TT_CONTROLS")
	ui.label(ui.tr("SET_DRAFT_HELP"), 20)
	match group:
		"video": _video()
		"audio": _audio()
		"accessibility": _accessibility()
		"controls": _controls()
	feedback = ui.label(ui.tr(session.error_key) if not session.error_key.is_empty() else "", 22)
	feedback.add_theme_color_override("font_color", Color("ffb5a6"))
	ui.button("SET_APPLY", apply)
	ui.button("SET_DEFAULTS", func() -> void:
		session.defaults(category)
		show_page(category))
	ui.button("UI_CANCEL", cancel)

func choice(key: String, data: Dictionary, field: String, values: Array, captions: Array = []) -> OptionButton:
	var caption: Label = ui.label(ui.tr(key), 24)
	var item := OptionButton.new()
	item.set_meta("settings_caption", weakref(caption))
	item.focus_entered.connect(ui._reveal_focus.bind(ui.generation), CONNECT_DEFERRED)
	item.name = key
	item.custom_minimum_size.y = 58
	for index: int in values.size():
		item.add_item(ui.tr(str(captions[index])) if not captions.is_empty() else str(values[index]))
	item.selected = values.find(data[field])
	ui.column.add_child(item)
	item.item_selected.connect(func(index: int) -> void: data[field] = values[index])
	return item

func slider(key: String, data: Dictionary, field: String, low: float, high: float, step: float = 0.05) -> void:
	var caption: Label = ui.label(ui.tr(key) + "  %d%%" % roundi(float(data[field]) * 100), 24)
	var item := HSlider.new()
	item.set_meta("settings_caption", weakref(caption))
	item.focus_entered.connect(ui._reveal_focus.bind(ui.generation), CONNECT_DEFERRED)
	item.name = key
	item.min_value = low
	item.max_value = high
	item.step = step
	item.value = float(data[field])
	item.custom_minimum_size = Vector2(240, 44)
	ui.column.add_child(item)
	item.value_changed.connect(func(value: float) -> void:
		data[field] = value
		caption.text = ui.tr(key) + "  %d%%" % roundi(value * 100))

func toggle(key: String, data: Dictionary, field: String) -> void:
	var item := CheckButton.new()
	item.name = key
	item.text = ui.tr(key)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.button_pressed = data[field]
	item.custom_minimum_size.y = 58
	ui.column.add_child(item)
	item.toggled.connect(func(value: bool) -> void: data[field] = value)

func _video() -> void:
	var data: Dictionary = session.draft.video
	var resolutions: Array = session.adapter.choices()
	if not resolutions.has(data.resolution) and int(data.resolution[0]) >= DisplayAdapter.MINIMUM.x and int(data.resolution[1]) >= DisplayAdapter.MINIMUM.y:
		resolutions.append(data.resolution.duplicate())
	var names: Array = []
	for resolution: Array in resolutions:
		names.append("%d × %d" % [resolution[0], resolution[1]])
	choice("SET_RESOLUTION", data, "resolution", resolutions, names)
	choice("SET_WINDOW", data, "window_mode", ["windowed", "fullscreen", "borderless"],
		["SET_WINDOWED", "SET_FULLSCREEN", "SET_BORDERLESS"])
	ui.label(ui.tr("SET_NATIVE_NOTE"), 20)
	toggle("SET_VSYNC", data, "vsync")
	choice("SET_FPS", data, "fps_limit", SettingsValues.FPS,
		["30", "60", "90", "120", "144", "165", "240", "SET_UNLIMITED"])
	choice("SET_QUALITY", data, "effects_quality", ["quality", "balanced", "performance"],
		["SET_QUALITY_HIGH", "SET_BALANCED", "SET_PERFORMANCE"])
	ui.label(ui.tr("SET_DECK_NOTE"), 20)
	slider("SET_POST", data, "post_intensity", 0, 1)
	slider("SET_SPEED", data, "speed_intensity", 0, 1)
	_shared_access()
	ui.label(ui.tr("SET_ASPECT_NOTE"), 20)

func _shared_access() -> void:
	var data: Dictionary = session.draft.accessibility
	# Legacy continuous shake values remain visible instead of being silently rounded.
	var values: Array = [0.0, 0.25, 0.5, 1.0]
	var names: Array = ["SET_OFF", "SET_LOW", "SET_MEDIUM", "SET_HIGH"]
	if not values.has(data.screen_shake):
		values.append(data.screen_shake)
		names.append("%d%%" % roundi(data.screen_shake * 100))
	choice("SET_SHAKE", data, "screen_shake", values, names)
	slider("SET_UI_SCALE", data, "ui_scale", 0.5, 2)
	slider("SET_HUD", data, "hud_opacity", 0.5, 1)

func _accessibility() -> void:
	var data: Dictionary = session.draft.accessibility
	toggle("SET_CONTRAST", data, "high_contrast")
	slider("SET_FLASH", data, "flash_intensity", 0, 1)
	toggle("SET_NO_FLASH", data, "disable_strong_flashes")
	choice("SET_COLORBLIND", data, "colorblind", SettingsValues.CORRECTIONS,
		["SET_OFF", "SET_PROTANOPIA", "SET_DEUTERANOPIA", "SET_TRITANOPIA"])
	slider("SET_TEXT", data, "text_size", 0.75, 1.5)
	slider("SET_SPEED", session.draft.video, "speed_intensity", 0, 1)
	_shared_access()

func _audio() -> void:
	for bus: String in SettingsValues.BUSES:
		slider("SET_BUS_" + bus.to_upper(), session.draft.audio, bus.to_lower(), 0, 1)
		toggle("SET_MUTE_" + bus.to_upper(), session.draft.audio.mutes, bus.to_lower())
	ui.label(ui.tr("SET_AUDIO_NOTE"), 20)

func _controls() -> void:
	ui.button("SET_PROFILE_" + profile.to_upper(), func() -> void:
		profile = "gamepad" if profile == "keyboard" else "keyboard"
		show_page(category))
	for action: String in InputBindings.ACTIONS:
		if action != InputBindings.canonical_action(action):
			continue
		ui.button("SET_ACTION_" + action.to_upper(), _capture.bind(action))
	refresh_prompts()
	for zone: String in ["movement", "dash", "activity"]:
		slider("SET_DEADZONE_" + zone.to_upper(), session.draft.controls.input.deadzones, zone, 0.05, 0.9)
	choice("SET_PROMPTS", session.draft.controls.input, "prompt_family", InputBindings.FAMILIES,
		["SET_AUTO", "SET_GENERIC", "Xbox", "PlayStation", "Nintendo", "Steam Deck"])
	ui.button("SET_RESET_PROFILE", func() -> void:
		ui.input_layer.reset_profile(profile)
		session.draft.controls.input = ui.input_layer.config.duplicate(true)
		show_page(category))

func refresh_prompts() -> void:
	if ui.screen != "settings_controls":
		return
	var family: String = session.draft.controls.input.prompt_family
	if family == "auto":
		family = InputPrompts.family_from_name(ui.input_layer.connected_pads.get(ui.input_layer.active_pad, ""))
	for action: String in InputBindings.ACTIONS:
		var key: String = "SET_ACTION_" + action.to_upper()
		var item := ui.panel.find_child(key, true, false) as Button
		if item == null:
			continue
		var tokens: Array = ui.input_layer.bindings(profile, action)
		item.text = ui.tr(key) + "  /  " + str(InputPrompts.descriptor(
			tokens[0] if not tokens.is_empty() else "", family).get("label", ""))

func _capture(action: String) -> void:
	capture = true
	ui.input_layer.begin_rebind(profile, action)
	feedback.text = ui.tr("TT_PRESS_BINDING")

func poll() -> void:
	if not capture or not ui.input_layer._capture_action.is_empty():
		return
	capture = false
	var result: Dictionary = ui.input_layer.last_rebind_result.duplicate()
	ui.input_layer.last_rebind_result.clear()
	session.draft.controls.input.profiles = ui.input_layer.config.profiles.duplicate(true)
	show_page(category)
	if not result.get("ok", false):
		feedback.text = ui.tr(result.get("message_key", "UI_CANCEL"))

func apply() -> void:
	ui.input_layer.set_options(session.draft.controls.input.deadzones,
		session.draft.controls.input.prompt_family)
	if not session.apply():
		feedback.text = ui.tr(session.error_key)
	elif session.previewing:
		var dialog := DisplayConfirmation.new()
		dialog.title = ui.tr("SET_CONFIRM_DISPLAY")
		dialog.dialog_text = ui.tr("SET_CONFIRM_HELP")
		dialog.ok_button_text = ui.tr("SET_KEEP")
		dialog.cancel_button_text = ui.tr("SET_REVERT")
		dialog.exclusive = true
		dialog.theme = IndustrialTheme.create()
		dialog.theme.default_font_size = roundi(24 * float(session.draft.accessibility.text_size))
		dialog.dialog_autowrap = true
		dialog.min_size = Vector2i(900, 260)
		dialog.confirmed.connect(session.keep)
		dialog.canceled.connect(session.revert)
		ui._present_modal(dialog)
		dialog.get_cancel_button().grab_focus()
	else:
		show_page(category)
		feedback.text = ui.tr("SET_SAVED")
		feedback.add_theme_color_override("font_color", Color("73e7d2"))

func cancel() -> void:
	session.cancel()
	ui.show_settings()
