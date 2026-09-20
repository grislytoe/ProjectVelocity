class_name LobbyView
extends RefCounted
## Sanitized presentation snapshot. No backend handles, persistent IDs or secrets.

var revision: int = 0
var code: String = ""
var local_host: bool = false
var host_name: String = ""
var guest_name: String = ""
var guest_connected: bool = false
var guest_ready: bool = false
var starting: bool = false
var settings: MatchSettings = MatchSettings.new()

func copy() -> LobbyView:
	var result := LobbyView.new()
	result.revision = revision
	result.code = code
	result.local_host = local_host
	result.host_name = host_name
	result.guest_name = guest_name
	result.guest_connected = guest_connected
	result.guest_ready = guest_ready
	result.starting = starting
	result.settings = settings.copy()
	return result

func valid(maps: Array[MapDefinition]) -> bool:
	return revision >= 0 and not code.is_empty() and JoinCode.normalize(code) == code and \
		PlayerProfileData.valid_nickname(host_name) and \
		(not guest_connected or PlayerProfileData.valid_nickname(guest_name)) and \
		(not guest_ready or guest_connected) and settings != null and settings.valid(maps)
