extends SceneTree
## Non-live deterministic contract evidence. No service credentials or native boundary.

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	var production := LobbyClient.new()
	check(not production.available(), "Production capability unavailable")
	production.create_lobby("Pilot")
	check(production.error_key == "EOS_UNAVAILABLE", "Production clean create failure")
	production.join_lobby("ABC234", "Pilot")
	check(production.error_key == "EOS_UNAVAILABLE", "Production clean join failure")
	var client := FakeLobbyClient.new()
	for character: String in JoinCode.ALPHABET:
		check(JoinCode.normalize(character.repeat(6)) == character.repeat(6), "Allowed alphabet")
	for code: String in ["", "ABCDE", "ABCDEFG", "ABC23O", "ABC230", "ABC231", "ABC23I",
		"ABC23L", "AB C23", "АBC234", "ABC23!", "ABC234x"]:
		client.join_lobby(code, "Pilot")
		check(client.error_key == "LOB_INVALID_CODE" and client.commands.is_empty(), "Invalid code")
	client.create_lobby("Pilot")
	check(client.phase == LobbyClient.Phase.CREATING and client.pending, "Create pending")
	client.join_lobby("invalid", "Pilot")
	check(client.phase == LobbyClient.Phase.CREATING and client.pending,
		"Repeated join cannot cancel an outstanding create")
	client.complete()
	check(client.phase == LobbyClient.Phase.LOBBY and client.view().code == "ABC234", "Create success")
	check(not client.can_start(), "No guest cannot start")
	var detached: LobbyView = client.view()
	detached.guest_connected = true
	detached.guest_ready = true
	detached.settings.rounds = 10
	check(not client.can_start() and client.view().settings.rounds == 3, "View cannot mutate authority")
	client.guest(true)
	check(not client.can_start(), "Unready guest cannot start")
	client.guest(true, true)
	check(client.can_start(), "Connected ready guest enables Start")
	var old: LobbyView = client.view()
	var settings: MatchSettings = old.settings.copy()
	settings.rounds = 10
	client.change_settings(settings)
	check(client.pending and not client.can_start(), "Settings atomically block Start")
	client.operation_failed(client.generation, client.request_id - 1, "LOB_FAILURE")
	check(client.pending and client.phase == LobbyClient.Phase.LOBBY, "Late operation error ignored")
	var unsolicited: LobbyView = old.copy()
	unsolicited.revision += 1
	client.receive(client.generation, unsolicited)
	check(client.pending and not client.can_start(), "Unsolicited update cannot unlock pending Start")
	# Use a newer authoritative revision for the fixture's actual acknowledgement.
	client.authority.revision += 1
	client.commands[0].revision += 1
	client.start_match()
	check(client.commands.size() == 1, "No concurrent start dispatch")
	client.complete()
	check(not client.view().guest_ready and not client.can_start() and
		client.metadata.rounds == 10 and not client.metadata.guest_ready, "Settings metadata resets Ready")
	client.receive(client.generation, old, client.request_id)
	check(not client.can_start() and client.view().settings.rounds == 10, "Stale host snapshot ignored")
	check(not client.authority_request("ready", false, old.revision, {"ready": true}), "Stale Ready rejected")
	check(not client.authority_request("start", true, old.revision, {}), "Stale Start rejected")
	client.guest(true, true)
	settings.map_id = client.maps[1].map_id
	client.change_settings(settings)
	client.complete()
	check(not client.view().guest_ready and client.metadata.compatibility.map == settings.map_id,
		"Map mutation resets ready and compatibility together")
	for rounds: int in [0, 11]:
		settings.rounds = rounds
		client.change_settings(settings)
		check(client.error_key == "LOB_REJECTED" and not client.pending, "Round bounds")
	client.guest(true, true)
	client.guest(false)
	check(not client.can_start() and not client.view().guest_ready, "Disconnect revokes readiness")
	client.guest(true, true)
	client.start_match()
	client.complete()
	check(client.start_requests == 1 and client.view().starting and not client.can_start(), "Single authoritative handoff")
	client.leave()
	client.join_lobby("  abc234  ", "Guest")
	check(client.phase == LobbyClient.Phase.SEARCHING and client.commands[0].payload.code == "ABC234", "Canonical search")
	client.searching_complete(client.generation)
	check(client.phase == LobbyClient.Phase.JOINING, "Join stage")
	client.complete()
	check(not client.view().local_host and client.view().guest_connected, "Guest slot")
	client.set_ready(true)
	client.complete()
	check(client.view().guest_ready, "Ready accepted")
	client.set_ready(false)
	client.complete()
	check(not client.view().guest_ready, "Ready withdrawn")
	client.set_ready(true)
	var requested: int = client.request_id
	client.authority_request("ready", false, client.authority.revision, {"ready": true})
	client.receive(client.generation, client.authority)
	check(client.pending, "Notification is not operation acknowledgement")
	client.receive(client.generation, client.authority, requested)
	check(not client.pending and client.view().guest_ready, "Same-revision ack after notification settles")
	client.commands.clear()
	client.change_settings(client.view().settings)
	client.start_match()
	check(client.commands.is_empty() and client.error_key == "LOB_REJECTED", "Guest UI permissions")
	check(not client.authority_request("settings", false, client.view().revision,
		{"settings": client.view().settings}), "Authority independently rejects guest settings")
	check(not client.authority_request("start", false, client.view().revision, {}), "Authority rejects guest Start")
	for key: String in LobbyClient.ERRORS + ["untrusted backend secret"]:
		client.leave()
		client.create_lobby("Pilot")
		client.fail(client.generation, key)
		check(client.phase == LobbyClient.Phase.FAILED and client.view() == null and
			client.error_key == (key if key in LobbyClient.ERRORS else "LOB_FAILURE"), "Clean allowlisted error")
	for index: int in 20:
		client.create_lobby("Pilot")
		var epoch: int = client.generation
		client.cancel()
		client.receive(epoch, old)
		check(client.error_key == "LOB_CANCELLED" and client.view() == null, "Late create after cancel")
		client.join_lobby("ABC234", "Guest")
		epoch = client.generation
		client.poll(Time.get_ticks_msec() + 15001)
		client.searching_complete(epoch)
		client.receive(epoch, old)
		check(client.error_key == "EOS_TIMEOUT" and client.view() == null, "Late join after timeout")
		client.leave()
		check(client.commands.is_empty() and client.metadata.is_empty() and not client.pending, "Lifecycle cleanup")
	if failures == 0:
		print("PROJECTVELOCITY_M20_CONTRACT_OK live=false native=false")
	quit(0 if failures == 0 else 1)
