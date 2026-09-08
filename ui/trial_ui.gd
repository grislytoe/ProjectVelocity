class_name TrialUI
extends CanvasLayer
## Application navigation and presentation. Gameplay lives in SoloTrial.

var store: SaveStore
var input_layer: InputLayer
var trial: SoloTrial
var panel: PanelContainer
var column: VBoxContainer
var hud: Label
var banner: Label
var status: Label
var screen: String = "menu"
var _message_ticks: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	input_layer.prompts_changed.connect(_prompts_changed)
	show_menu()

func _panel(title: String) -> void:
	if is_instance_valid(panel):
		panel.free()
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -390
	panel.offset_right = 390
	panel.offset_top = -430
	panel.offset_bottom = 430
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101f2bf5")
	style.border_color = Color("3ecac9")
	style.set_border_width_all(2)
	style.content_margin_left = 36
	style.content_margin_right = 36
	style.content_margin_top = 24
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var scroll := ScrollContainer.new()
	panel.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 16)
	scroll.add_child(column)
	label(tr(title), 40)

func label(text: String, size: int = 25) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", size)
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(item)
	return item

func button(key: String, callback: Callable) -> Button:
	var item := Button.new()
	item.text = tr(key)
	item.custom_minimum_size.y = 56
	item.add_theme_font_size_override("font_size", 26)
	item.pressed.connect(func() -> void: callback.call_deferred())
	column.add_child(item)
	return item

func _leave() -> void:
	get_tree().paused = false
	if is_instance_valid(trial):
		trial.free()
	trial = null
	for item: Label in [hud, banner, status]:
		if is_instance_valid(item):
			item.free()
	hud = null
	banner = null
	status = null
	input_layer.clear_transient_state()

func show_menu() -> void:
	_leave()
	screen = "menu"
	_panel("APP_TITLE")
	label(store.data.profile.nickname, 28)
	label(BuildInfo.label(), 20)
	button("TT_SOLO", show_maps).grab_focus()
	button("TT_CONTROLS", show_controls)
	button("TT_LANGUAGE", toggle_language)
	button("TT_QUIT", func() -> void: get_tree().quit())
	if not store.notification_key.is_empty():
		label(tr(store.notification_key), 22)

func toggle_language() -> void:
	var language: String = "ru" if TranslationServer.get_locale().begins_with("en") else "en"
	TranslationServer.set_locale(language)
	store.data.profile.language = language
	store.save()
	show_menu()

func show_maps() -> void:
	_leave()
	screen = "maps"
	_panel("TT_SELECT")
	label(tr("TT_MAP_DESCRIPTION"))
	var repository := TrialRecords.new(store, TrialMapDefinition.new())
	var best: Dictionary = repository.best()
	label(tr("TT_PB") % ("—" if best.is_empty() else TrialRecord.format_time(int(best.total))))
	button("TT_MAP", start_map).grab_focus()
	button("TT_MENU", show_menu)

func show_controls() -> void:
	screen = "controls"
	_panel("TT_CONTROLS")
	label(tr("TT_REBIND_HELP"))
	for action: String in ["jump", "dash", "restart", "pause"]:
		var item: Button = button("TT_BIND_" + action.to_upper(), rebind.bind(action))
		item.text += "  ·  " + str(input_layer.prompt(action).get("label", ""))
	button("TT_MENU", show_menu).grab_focus()

func rebind(action: String) -> void:
	input_layer.begin_rebind("gamepad" if input_layer.last_device == "controller" else "keyboard", action)
	label(tr("TT_PRESS_BINDING"))

func start_map() -> void:
	_leave()
	screen = "trial"
	if is_instance_valid(panel):
		panel.free()
	hud = Label.new()
	hud.position = Vector2(32, 24)
	hud.add_theme_font_size_override("font_size", 34)
	add_child(hud)
	banner = Label.new()
	banner.position = Vector2(650, 155)
	banner.size = Vector2(620, 140)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 72)
	add_child(banner)
	status = Label.new()
	status.position = Vector2(32, 120)
	status.add_theme_font_size_override("font_size", 26)
	add_child(status)
	trial = SoloTrial.new()
	trial.process_mode = Node.PROCESS_MODE_PAUSABLE
	trial.layer = input_layer
	trial.records = TrialRecords.new(store, TrialMapDefinition.new())
	trial.changed.connect(refresh.call_deferred)
	trial.message.connect(show_message)
	get_parent().add_child(trial)
	refresh()

func refresh() -> void:
	if not is_instance_valid(trial):
		return
	if is_instance_valid(panel):
		panel.free()
	if trial.phase == SoloTrial.Phase.HINT:
		_panel("TT_CONTROLS")
		label(tr("TT_HINT") % [input_layer.prompt("move_left").get("label", ""),
			input_layer.prompt("move_right").get("label", ""), input_layer.prompt("jump").get("label", ""),
			input_layer.prompt("dash").get("label", ""), input_layer.prompt("restart").get("label", ""),
			input_layer.prompt("pause").get("label", "")])
		button("TT_READY", trial.dismiss_hint).grab_focus()
	elif trial.phase == SoloTrial.Phase.RESULT:
		_panel("TT_RESULTS")
		label(TrialRecord.format_time(trial.elapsed), 52)
		label(tr("TT_NEW_PB" if trial.result.new_pb else "TT_COMPLETE") if trial.valid else tr("TT_INVALID"))
		if trial.valid and not trial.result.saved:
			label(tr("TT_SAVE_FAILED"))
		label(tr("TT_PB_DELTA") % ("—" if trial.baseline.is_empty() else
			TrialRecord.delta(trial.elapsed - int(trial.baseline.total))))
		label(tr("TT_DEATHS") % trial.deaths)
		for index: int in trial.splits.size():
			var difference: String = "—" if trial.baseline.is_empty() else TrialRecord.delta(
				trial.splits[index] - int(trial.baseline.splits[index]))
			label(tr("TT_SPLIT") % [index + 1, TrialRecord.format_time(trial.splits[index]), difference], 22)
		button("TT_RETRY", trial.request_retry).grab_focus()
		button("TT_SELECT", show_maps)
		button("TT_MENU", show_menu)

func _prompts_changed() -> void:
	if screen == "controls":
		show_controls.call_deferred()
	elif is_instance_valid(trial) and trial.phase == SoloTrial.Phase.HINT:
		refresh.call_deferred()

func show_message(key: String) -> void:
	if is_instance_valid(status):
		status.text = tr(key)
		if key == "M7_CHECKPOINT" and is_instance_valid(trial):
			status.text += "  " + trial.live_delta
		_message_ticks = 150

func _process(_delta: float) -> void:
	if screen == "controls" and not input_layer.last_rebind_result.is_empty():
		var feedback: Dictionary = input_layer.last_rebind_result.duplicate()
		input_layer.last_rebind_result.clear()
		show_controls()
		if not feedback.get("ok", false):
			label(tr(feedback.get("message_key", "INPUT_BINDING_INVALID")))
	if not is_instance_valid(trial):
		return
	hud.text = TrialRecord.format_time(trial.elapsed) + "   " + tr("TT_PB") % (
		"—" if trial.baseline.is_empty() else TrialRecord.format_time(int(trial.baseline.total)))
	hud.text += "\n" + BuildInfo.label()
	banner.text = ""
	if trial.phase == SoloTrial.Phase.COUNTDOWN:
		banner.text = str(ceili(float(trial.barrier.gate.start_tick - trial.tick) / 60.0))
	elif trial.phase == SoloTrial.Phase.RUN and trial.elapsed < 60:
		banner.text = tr("M7_GO")
	if not trial.valid:
		status.text = tr("TT_INVALID")
	elif _message_ticks <= 0:
		status.text = trial.live_delta

func _physics_process(_delta: float) -> void:
	if not get_tree().paused:
		_message_ticks = maxi(0, _message_ticks - 1)

func _input(event: InputEvent) -> void:
	if not is_instance_valid(trial) or trial.phase == SoloTrial.Phase.RESULT:
		return
	if event.is_action_pressed(input_layer.action_name("pause")):
		toggle_pause.call_deferred()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	input_layer.clear_transient_state()
	if get_tree().paused:
		_panel("TT_PAUSED")
		button("TT_RESUME", toggle_pause).grab_focus()
		button("TT_SELECT", show_maps)
		button("TT_MENU", show_menu)
	else:
		refresh()

func _exit_tree() -> void:
	get_tree().paused = false
