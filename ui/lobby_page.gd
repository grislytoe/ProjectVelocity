class_name LobbyPage
extends RefCounted
## Uses AppUI's panel, theme, transition, modal and focus ownership.

var ui: AppUI
var service: LobbyClient
var clipboard: LobbyClipboard = LobbyClipboard.new()
var code_entry: LineEdit
var draft_code: String = ""
var last_action: String = "create"
var active: bool = false
var notice: Label
var _redraw_queued: bool = false

func _init(owner: AppUI, client: LobbyClient) -> void:
	ui = owner
	service = client
	service.changed.connect(_changed)

func dispose() -> void:
	active = false
	service.changed.disconnect(_changed)
	service.leave()
	ui = null

func entry() -> void:
	active = true
	ui.screen = "online"
	ui._panel("UI_ONLINE")
	if not service.available():
		ui.label(ui.tr("EOS_UNAVAILABLE"), 24)
	else:
		ui.label(ui.tr("LOB_PRIVATE"), 24)
	for action: String in ["create", "join"]:
		var item: Button = ui.button("UI_CREATE_LOBBY" if action == "create" else "UI_JOIN_LOBBY",
			create if action == "create" else join_form)
		item.disabled = not service.available()
		item.focus_mode = Control.FOCUS_ALL if service.available() else Control.FOCUS_NONE
	ui.button("UI_BACK", leave)

func create() -> void:
	last_action = "create"
	service.create_lobby(ui.store.data.profile.nickname)

func join_form() -> void:
	last_action = "join"
	ui.screen = "online_join"
	ui._panel("UI_JOIN_LOBBY")
	ui.label(ui.tr("LOB_CODE_HELP"), 24)
	code_entry = LineEdit.new()
	code_entry.name = "LobbyCode"
	code_entry.accessibility_name = ui.tr("LOB_CODE")
	code_entry.placeholder_text = ui.tr("LOB_CODE")
	code_entry.max_length = 0 # Never truncate a pasted invalid code into a valid one.
	code_entry.text = draft_code
	code_entry.custom_minimum_size.y = 58
	ui.column.add_child(code_entry)
	ui.button("UI_KEYBOARD", keyboard)
	notice = ui.label("", 22)
	ui.button("UI_JOIN_LOBBY", join)
	ui.button("UI_BACK", entry)
	code_entry.text_changed.connect(func(value: String) -> void:
		draft_code = value
		notice.text = "" if not JoinCode.normalize(value).is_empty() else ui.tr("LOB_INVALID_CODE"))
	code_entry.text_submitted.connect(func(_value: String) -> void:
		if not ui.busy:
			join())

func keyboard() -> void:
	var window := NameKeyboard.new()
	window.code_mode = true
	window.value = draft_code
	window.accepted.connect(func(value: String) -> void:
		draft_code = value
		code_entry.text = value
		code_entry.text_changed.emit(value))
	ui._present_modal(window)

func join() -> void:
	draft_code = code_entry.text
	var canonical: String = JoinCode.normalize(draft_code)
	if not canonical.is_empty():
		draft_code = canonical
	service.join_lobby(draft_code, ui.store.data.profile.nickname)

func _changed() -> void:
	# Rebuild outside GUI signal traversal. Multiple events coalesce to latest state.
	if active and not _redraw_queued:
		var focused: Control = ui.get_viewport().gui_get_focus_owner()
		if focused != null:
			ui.remembered[ui.screen] = focused.name
		_redraw_queued = true
		_redraw.call_deferred()

func _redraw() -> void:
	_redraw_queued = false
	if not active:
		return
	match service.phase:
		LobbyClient.Phase.ENTRY: entry()
		LobbyClient.Phase.FAILED:
			ui.screen = "online_error"
			ui._panel("UI_ONLINE")
			ui.label(ui.tr(service.error_key), 28)
			ui.button("LOB_RETRY", create if last_action == "create" else join_form)
			ui.button("UI_BACK", entry)
		LobbyClient.Phase.LOBBY: lobby()
		_:
			ui.screen = "online_pending"
			ui._panel("UI_ONLINE")
			var key: String = "LOB_CREATING"
			if service.phase == LobbyClient.Phase.SEARCHING:
				key = "LOB_SEARCHING"
			elif service.phase == LobbyClient.Phase.JOINING:
				key = "LOB_JOINING"
			ui.label(ui.tr(key), 28)
			ui.button("UI_CANCEL", service.cancel)

func lobby() -> void:
	var snapshot: LobbyView = service.view()
	ui.screen = "online_lobby"
	ui._panel("LOB_TITLE")
	ui.label(ui.tr("LOB_PRIVATE"), 22)
	var code_row := HBoxContainer.new()
	ui.column.add_child(code_row)
	var code_label: Label = ui.label(ui.tr("LOB_CODE") + "  /  " + snapshot.code, 38)
	code_label.reparent(code_row)
	code_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var copy_button: Button = ui.button("LOB_COPY", copy_code)
	copy_button.reparent(code_row)
	copy_button.custom_minimum_size.x = 310
	var host: String = ui.tr("LOB_HOST")
	var guest: String = ui.tr("LOB_GUEST")
	if snapshot.local_host:
		host += " · " + ui.tr("LOB_LOCAL")
	else:
		guest += " · " + ui.tr("LOB_LOCAL")
	ui.label(host + "  /  " + snapshot.host_name + " · " + ui.tr("LOB_CONNECTED"), 24)
	ui.label(guest + "  /  " + (snapshot.guest_name + " · " + ui.tr("LOB_CONNECTED") +
		" · " + ui.tr("LOB_READY" if snapshot.guest_ready else "LOB_NOT_READY")
		if snapshot.guest_connected else ui.tr("LOB_WAITING")), 24)
	for map: MapDefinition in service.maps:
		if map.map_id == snapshot.settings.map_id:
			ui.label(ui.tr(map.name_key), 30)
			ui.label(ui.tr("LOB_MAP_INFO") % [ui.tr(map.difficulty_key),
				map.expected_duration_seconds, map.map_version, map.declared_checksum.left(12)], 20)
	ui.label(ui.tr("LOB_ROUNDS") % snapshot.settings.rounds, 26)
	if snapshot.local_host:
		var select: OptionButton = OptionButton.new()
		select.name = "LobbyMap"
		select.accessibility_name = ui.tr("TT_SELECT")
		select.custom_minimum_size.y = 50
		for map: MapDefinition in service.maps:
			select.add_item(ui.tr(map.name_key))
			if map.map_id == snapshot.settings.map_id:
				select.select(select.item_count - 1)
		select.disabled = service.pending or snapshot.starting
		ui.column.add_child(select)
		select.item_selected.connect(func(index: int) -> void:
			var settings: MatchSettings = snapshot.settings.copy()
			settings.map_id = service.maps[index].map_id
			service.change_settings(settings))
		var rounds := HSlider.new()
		rounds.name = "LobbyRounds"
		rounds.min_value = 1
		rounds.max_value = 10
		rounds.step = 1
		rounds.value = snapshot.settings.rounds
		rounds.editable = not service.pending and not snapshot.starting
		rounds.custom_minimum_size.y = 40
		rounds.accessibility_name = ui.tr("LOB_ROUNDS_LABEL")
		ui.column.add_child(rounds)
		rounds.value_changed.connect(func(value: float) -> void:
			var settings: MatchSettings = snapshot.settings.copy()
			settings.rounds = int(value)
			service.change_settings(settings))
		ui.button("LOB_START", service.start_match).disabled = not service.can_start()
	else:
		ui.button("LOB_NOT_READY" if snapshot.guest_ready else "LOB_READY",
			service.set_ready.bind(not snapshot.guest_ready)).disabled = service.pending or snapshot.starting
	var message: String = service.error_key
	if service.pending:
		message = "LOB_UPDATING"
	elif snapshot.starting:
		message = "LOB_STARTING"
	notice = ui.label(ui.tr(message) if not message.is_empty() else ui.tr("LOB_RESET_HELP"), 22)
	ui.button("LOB_LEAVE", leave)

func copy_code() -> void:
	var snapshot: LobbyView = service.view()
	if snapshot != null:
		notice.text = ui.tr("LOB_COPIED" if clipboard.copy_code(snapshot.code) else "LOB_COPY_MANUAL")

func back() -> void:
	if service.pending:
		service.cancel()
	elif ui.screen == "online_lobby" or ui.screen == "online":
		leave()
	else:
		entry()

func leave() -> void:
	active = false
	service.leave()
	ui.show_new_game()
