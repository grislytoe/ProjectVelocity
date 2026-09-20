extends "res://tests/ui_foundation_test.gd"
## Real Godot GUI with an explicitly injected non-live service; isolated saves only.

class ClipboardFixture extends LobbyClipboard:
	var copied: String = ""
	var enabled: bool = true
	func copy_code(code: String) -> bool:
		copied = code
		return enabled

func run() -> void:
	capture_enabled = OS.get_cmdline_user_args().has("--render-capture")
	capture_suffix = "-m20"
	folder = OS.get_cache_dir().path_join("pv-m20-test-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated UI save")
	store.data.onboarding_complete = true
	store.data.profile.nickname = "Local Pilot"
	main = preload("res://core/bootstrap/main.tscn").instantiate()
	main.save_store = store
	root.add_child(main)
	await process_frame
	await process_frame
	ui = main.get_children().filter(func(node: Node) -> bool: return node is AppUI)[0]
	ui.show_online()
	await settle()
	check(find_button("UI_CREATE_LOBBY").disabled and find_button("UI_JOIN_LOBBY").disabled,
		"Production adapter cannot simulate success")
	check(root.gui_get_focus_owner() == find_button("UI_BACK"), "Unavailable Back focus")
	await capture("unavailable")
	ui.lobby_page.dispose()
	ui.lobby_page = null
	var client := FakeLobbyClient.new()
	ui.lobby_client = client
	ui.show_online()
	var clipboard := ClipboardFixture.new()
	ui.lobby_page.clipboard = clipboard
	await settle()
	print("M20_STAGE create")
	await mouse("UI_CREATE_LOBBY")
	check(ui.screen == "online_pending" and client.phase == LobbyClient.Phase.CREATING, "Mouse create pending")
	var cancelled_epoch: int = client.generation
	await activate("UI_CANCEL")
	check(ui.screen == "online_error" and client.error_key == "LOB_CANCELLED", "Cancel visible")
	await activate("LOB_RETRY")
	client.complete()
	await settle()
	check(ui.screen == "online_lobby", "Create success screen")
	var old_view: LobbyView = client.view()
	client.receive(cancelled_epoch, old_view)
	check(not find_button("LOB_START").is_pressed() and find_button("LOB_START").disabled, "Start waits for guest")
	await activate("LOB_COPY")
	check(clipboard.copied == "ABC234" and ui.lobby_page.notice.text == ui.tr("LOB_COPIED"), "Copy code port")
	clipboard.enabled = false
	await activate("LOB_COPY")
	check(ui.lobby_page.notice.text == ui.tr("LOB_COPY_MANUAL"), "Copy fallback")
	client.guest(true, true)
	await settle()
	check(not find_button("LOB_START").disabled, "Ready Start enabled")
	ui.input_layer.update_connection(42, true, "Xbox Controller")
	var rounds: HSlider = ui.panel.find_child("LobbyRounds", true, false)
	rounds.grab_focus()
	await action("ui_right", true)
	check(find_button("LOB_START").disabled, "Mutation pending blocks Start")
	client.complete()
	await settle()
	check(client.view().settings.rounds == 4 and not client.view().guest_ready and
		find_button("LOB_START").disabled, "Controller rounds and acknowledged reset")
	var map_select: OptionButton = ui.panel.find_child("LobbyMap", true, false)
	map_select.grab_focus()
	await action("ui_accept", true)
	await action("ui_down", true)
	await action("ui_accept", true)
	client.complete()
	await settle()
	check(client.view().settings.map_id == client.maps[1].map_id, "Map UI intent")
	print("M20_STAGE captures")
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		for key: String in LobbyClient.ERRORS:
			check(ui.tr(key) != key, "Localized error " + key)
		client.guest(true, true)
		for viewport: Vector2i in [Vector2i(1920, 1080), Vector2i(1280, 800)]:
			root.size = viewport
			ui.lobby_page.lobby()
			await settle()
			check(root.size == viewport, "Representative window size")
			await capture("lobby-" + locale + "-" + str(viewport.x))
			find_button("LOB_LEAVE").grab_focus()
			await action("ui_focus_next")
			check(root.gui_get_focus_owner() != null, "Keyboard focus loop")
	print("M20_STAGE guest")
	await activate("LOB_START", true)
	client.complete()
	await settle()
	check(client.start_requests == 1 and client.view().starting, "Controller Start dispatches authority intent")
	await activate("LOB_LEAVE", true)
	check(client.view() == null and ui.screen == "new_game", "Controller leave cleans service")
	await activate("UI_ONLINE", true)
	await activate("UI_JOIN_LOBBY", true)
	check(ui.screen == "online_join", "Join form")
	await capture("code-entry")
	await activate("UI_KEYBOARD", true)
	var keyboard: NameKeyboard = ui.modal
	check(keyboard.code_mode and keyboard.keys.get_child_count() == JoinCode.ALPHABET.length(), "Code-only keyboard")
	await capture("code-keyboard")
	var event := InputEventJoypadButton.new()
	event.device = 42
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	keyboard.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	keyboard.push_input(event, true)
	await process_frame
	check(keyboard.field.text == "A", "Controller enters allowed character")
	check(ui.prompt.text.contains(str(ui.input_layer.prompt("ui_accept").get("label", ""))),
		"Controller prompt follows active input device")
	keyboard._cancel()
	await settle()
	check(ui.lobby_page.code_entry.text.is_empty() and root.gui_get_focus_owner() == find_button("UI_KEYBOARD"),
		"Cancelling code keyboard preserves draft and focus")
	await activate("UI_KEYBOARD", true)
	keyboard = ui.modal
	keyboard.field.text = "abc234"
	keyboard._accept()
	await settle()
	check(root.gui_get_focus_owner() == find_button("UI_KEYBOARD"), "Code modal restores focus")
	check(ui.lobby_page.code_entry.text == "abc234", "Modal applies code")
	await activate("UI_JOIN_LOBBY", true)
	check(client.phase == LobbyClient.Phase.SEARCHING and ui.lobby_page.draft_code == "ABC234", "Canonical UI search")
	client.searching_complete(client.generation)
	await settle()
	await capture("joining")
	client.complete()
	await settle()
	check(ui.panel.find_child("LobbyMap", true, false) == null and find_button("LOB_START") == null,
		"Guest has no host controls")
	await activate("LOB_READY", true)
	client.complete()
	await settle()
	check(client.view().guest_ready and find_button("LOB_NOT_READY") != null, "Controller ready")
	await activate("LOB_NOT_READY")
	client.complete()
	await settle()
	check(not client.view().guest_ready, "Keyboard withdraw")
	await capture("guest")
	client.fail(client.generation, "LOB_HOST_LEFT")
	await settle()
	await capture("host-left")
	check(ui.screen == "online_error", "Host departure UI")
	await activate("LOB_RETRY")
	ui.lobby_page.code_entry.text = "ABC23O"
	await activate("UI_JOIN_LOBBY")
	check(client.error_key == "LOB_INVALID_CODE", "Invalid pasted code visible")
	await activate("LOB_RETRY")
	ui.lobby_page.code_entry.text = "ABC234"
	await activate("UI_JOIN_LOBBY")
	client.poll(Time.get_ticks_msec() + 15001)
	await settle()
	check(client.error_key == "EOS_TIMEOUT", "UI timeout")
	for key: String in LobbyClient.ERRORS:
		client.fail(client.generation, key)
		await settle()
		check(ui.screen == "online_error" and ui.panel.find_children("*", "Label", true, false).any(
			func(item: Label) -> bool: return item.text == ui.tr(key)), "Rendered error contract " + key)
	print("M20_STAGE lifecycle")
	var connections: int = client.changed.get_connections().size()
	for index: int in 12:
		ui.lobby_page.leave()
		ui.show_online()
		ui.lobby_page.create()
		client.complete()
		await settle()
	check(client.changed.get_connections().size() == connections, "No duplicate service subscriptions")
	ui.show_menu()
	await settle()
	check(not ui.lobby_page.active and client.view() == null and ui.screen == "menu",
		"Navigation outside Online invalidates deferred callbacks and leaves")
	ui.lobby_page.leave()
	await settle()
	main.input_preferences.flush()
	main.free()
	await process_frame
	check(client.changed.get_connections().is_empty() and client.view() == null, "UI teardown disconnects service")
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	if failures == 0:
		print("PROJECTVELOCITY_M20_UI_OK live=false native=false simulated_input=true")
	quit(0 if failures == 0 else 1)
