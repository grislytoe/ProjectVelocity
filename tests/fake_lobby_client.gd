class_name FakeLobbyClient
extends LobbyClient
## Deterministic test-only executor. Not loaded by production composition or exports.
## Host fixture reuses M16 ReadyStart; this does not run a network match or EOS.

var commands: Array[Dictionary] = []
var authority: LobbyView
var gate := ReadyStart.new()
var metadata: Dictionary = {}
var cleanup_count: int = 0
var start_requests: int = 0

func available() -> bool:
	return OS.is_debug_build()

func _dispatch(command: String, epoch: int, revision: int, payload: Dictionary) -> void:
	commands.append({"command": command, "epoch": epoch, "revision": revision,
		"request": request_id, "payload": payload})

func _cleanup(_epoch: int) -> void:
	cleanup_count += 1
	authority = null
	metadata.clear()
	commands.clear()
	gate.configure([&"1", &"2"])

func complete() -> void:
	if commands.is_empty():
		return
	var operation: Dictionary = commands.pop_front()
	var command: String = operation.command
	if command in ["create", "join"]:
		authority = LobbyView.new()
		authority.code = "ABC234" if command == "create" else operation.payload.code
		authority.local_host = command == "create"
		authority.host_name = operation.payload.nickname if authority.local_host else "Host Pilot"
		authority.guest_name = "" if authority.local_host else operation.payload.nickname
		authority.guest_connected = not authority.local_host
		authority.settings.map_id = maps[0].map_id
		if command == "join":
			searching_complete(operation.epoch)
	elif not authority_request(command, authority.local_host, operation.revision, operation.payload):
		reject()
		pending = false
		return
	_publish(operation.epoch, operation.request)

func authority_request(command: String, host: bool, revision: int, payload: Dictionary) -> bool:
	if authority == null or revision != authority.revision or authority.starting:
		return false
	match command:
		"settings":
			if not host or not payload.settings.valid(maps):
				return false
			authority.settings = payload.settings.copy()
			authority.guest_ready = false
			gate.set_ready(&"2", false)
		"ready":
			if host or not authority.guest_connected:
				return false
			authority.guest_ready = payload.ready
			gate.set_ready(&"2", payload.ready)
		"start":
			if not host or not authority.guest_connected or not authority.guest_ready:
				return false
			# Only records accepted lobby handoff; map loading/hints/GO remain M16's job.
			if not gate.participants.get(&"2", false):
				return false
			authority.starting = true
			start_requests += 1
		_: return false
	authority.revision += 1
	return true

func guest(connected: bool, ready: bool = false) -> void:
	authority.guest_connected = connected
	authority.guest_name = "Guest Pilot" if connected else ""
	authority.guest_ready = connected and ready
	gate.set_ready(&"2", authority.guest_ready)
	authority.revision += 1
	_publish(generation)

func _publish(epoch: int, acknowledgement: int = -1) -> void:
	for map: MapDefinition in maps:
		if map.map_id == authority.settings.map_id:
			metadata = {"compatibility": LobbyPolicy.metadata(authority.code, map),
				"rounds": authority.settings.rounds, "revision": authority.revision,
				"guest_ready": authority.guest_ready}
	receive(epoch, authority, acknowledgement)
