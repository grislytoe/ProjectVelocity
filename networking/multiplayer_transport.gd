class_name MultiplayerTransport
extends RefCounted
## Session sees only validated, serializable packet values and connection state.

var connected: bool = false
var rejected: int = 0
var config := NetworkConfig.new()
var error: String = ""

func send(_packet: NetPacket) -> void:
	pass

func poll(_tick: int) -> Array[NetPacket]:
	return []

func close() -> void:
	connected = false
