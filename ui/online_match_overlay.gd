class_name OnlineMatchOverlay
extends Control
## M21 presentation only. All displayed lifecycle data comes from NetworkSession snapshots.

signal route_requested(route: String)

var session: NetworkSession
var input_layer: InputLayer
var phase_label: Label
var result_label: Label
var actions: HBoxContainer
var ready_button: Button
var play_again_button: Button
var lobby_button: Button
var menu_button: Button

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 300)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	phase_label = Label.new()
	phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phase_label.add_theme_font_size_override("font_size", 34)
	column.add_child(phase_label)
	result_label = Label.new()
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.add_theme_font_size_override("font_size", 24)
	column.add_child(result_label)
	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(actions)
	ready_button = _button("M21_READY", _ready_next)
	play_again_button = _button("M21_PLAY_AGAIN", _play_again)
	lobby_button = _button("M21_RETURN_LOBBY", _return_lobby)
	menu_button = _button("M21_MAIN_MENU", _main_menu)
	hide()

func bind(value: NetworkSession, layer: InputLayer) -> void:
	session = value
	input_layer = layer

func _button(key: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = key
	button.text = tr(key)
	button.custom_minimum_size = Vector2(210, 56)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(callback)
	actions.add_child(button)
	return button

func refresh() -> void:
	if session == null:
		hide()
		return
	var phase: int = session.phase()
	var show_results: bool = phase in [OnlineSeries.Phase.ROUND_RESULTS,
		OnlineSeries.Phase.BETWEEN_ROUND_READY, OnlineSeries.Phase.FINAL_SERIES_RESULTS]
	visible = show_results
	if not show_results:
		return
	phase_label.text = tr("M21_SERIES_RESULTS" if phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS \
		else "M21_ROUND_RESULTS")
	result_label.text = _summary()
	ready_button.visible = phase == OnlineSeries.Phase.BETWEEN_ROUND_READY
	play_again_button.visible = phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS
	lobby_button.visible = phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS
	menu_button.visible = phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS
	play_again_button.disabled = not session.host
	if get_viewport().gui_get_focus_owner() == null or not get_viewport().gui_get_focus_owner().is_visible_in_tree():
		if ready_button.visible: ready_button.grab_focus.call_deferred()
		elif play_again_button.visible and not play_again_button.disabled: play_again_button.grab_focus.call_deferred()
		else: lobby_button.grab_focus.call_deferred()

func _summary() -> String:
	var series: OnlineSeries = session.series
	var lines: Array[String] = [tr("M21_ROUND") % [series.round_index, series.rounds_total],
		tr("M21_SCORE") % [series.score[0], series.score[1]]]
	for result: Array in series.round_results:
		var times: Array = result[5]
		lines.append(tr("M21_RESULT_ROW") % [result[0], _time(times[0]), _time(times[1])])
	if series.phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS:
		lines.append(tr("M21_DRAW") if series.final_winner == 0 else tr("M21_WINNER") % series.final_winner)
		lines.append(tr("M21_BEST_ROW") % [_time(series.best_times[0]), _time(series.best_times[1])])
	else:
		lines.append(tr("M21_WAIT_READY"))
	return "\n".join(lines)

func _time(ticks: int) -> String:
	return tr("M21_DNF") if ticks < 0 else "%02d:%02d.%03d" % [ticks / 3600,
		(ticks / 60) % 60, (ticks % 60) * 1000 / 60]

func _ready_next() -> void:
	session.set_local_ready(true)
	ready_button.disabled = true

func _play_again() -> void:
	if session.request_series_action(OnlineSeries.Action.PLAY_AGAIN):
		hide()

func _return_lobby() -> void:
	if session.host: session.request_series_action(OnlineSeries.Action.RETURN_TO_LOBBY)
	route_requested.emit("lobby")

func _main_menu() -> void:
	if session.host: session.request_series_action(OnlineSeries.Action.MAIN_MENU)
	route_requested.emit("menu")

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		for button: Button in [ready_button, play_again_button, lobby_button, menu_button]:
			button.text = tr(button.name)
		refresh()
