class_name EOSP2PTransport
extends MultiplayerTransport
## M19 adapter policy against a NON-LIVE authenticated datagram boundary.
## EOSG 2.3.0 erases source PUID on its game packet queue: see M19_BLOCKERS.md.
## Therefore there is deliberately no production boundary factory / native open here.
## An envelope's sender/socket MUST come from the service, never payload claims.

const MAX_QUEUE: int = 256
const MAX_POLL: int = 128
const SOCKET_PREFIX: String = "PV19"
const CONTROL_CHANNEL: int = 1
const DATA_CHANNEL: int = 2
var _boundary: RefCounted
var _local: String = ""
var _remote: String = ""
var _socket: String = ""
var _epoch: String = ""
var _outbox: Array[Dictionary] = []
var _fragments := PacketFragments.new()
var _incoming_control := PacketFragments.new()
var _incoming_data := PacketFragments.new()

func open() -> Error:
	close()
	error = EOSCapability.unavailable_key()
	return ERR_UNAVAILABLE

func attach_test_boundary(boundary: RefCounted, members: Array[String], local: String,
		epoch: String) -> Error:
	close()
	if not OS.is_debug_build() or boundary == null or not boundary.has_method("is_non_live_fixture"):
		return ERR_UNAVAILABLE
	if not boundary.call("is_non_live_fixture") or members.size() != 2 or local.is_empty() or \
		members[0].is_empty() or members[1].is_empty() or members[0] == members[1] or \
		not members.has(local) or not NetPacket.hex(epoch, 24):
		return ERR_INVALID_PARAMETER
	_boundary = boundary
	_local = local
	_remote = members[1] if local == members[0] else members[0]
	_epoch = epoch
	_socket = SOCKET_PREFIX + epoch # 28 alphanumeric chars, new random nonce per lobby epoch.
	connected = true
	error = ""
	return OK

func accepts(sender: String, socket: String) -> bool:
	return connected and sender == _remote and socket == _socket

func send(packet: NetPacket) -> void:
	if not connected or packet == null:
		return
	var bytes: PackedByteArray = packet.encode(config)
	if NetPacket.decode(bytes, config) == null:
		rejected += 1
		return
	var parts: Array[PackedByteArray] = _fragments.split(bytes)
	if _outbox.size() + parts.size() > MAX_QUEUE:
		rejected += 1 # Whole-message admission; no partial send due to our queue cap.
		error = "EOS_BACKPRESSURE"
		return
	var reliable: bool = _reliable(packet.kind)
	for part: PackedByteArray in parts:
		_outbox.append({"sender": _local, "target": _remote, "socket": _socket,
			"epoch": _epoch, "channel": CONTROL_CHANNEL if reliable else DATA_CHANNEL,
			"reliable": reliable, "bytes": part})

func poll(tick: int) -> Array[NetPacket]:
	var packets: Array[NetPacket] = []
	if not connected or _boundary == null:
		return packets
	for i: int in mini(_outbox.size(), MAX_POLL):
		if not _boundary.call("send_datagram", _outbox[0]):
			break # Retry pending in order; boundary must bound its native queue separately.
		_outbox.pop_front()
	_incoming_control.prune(tick)
	_incoming_data.prune(tick)
	for i: int in MAX_POLL:
		var envelope: Variant = _boundary.call("receive_datagram")
		if envelope == null:
			break
		if not _valid_envelope(envelope):
			rejected += 1
			continue
		var assembler: PacketFragments = _incoming_control if envelope.reliable else _incoming_data
		var before: int = assembler.rejected
		var bytes: PackedByteArray = assembler.join(envelope.bytes, tick)
		rejected += assembler.rejected - before
		if bytes.is_empty():
			continue
		var packet: NetPacket = NetPacket.decode(bytes, config)
		if packet == null or _reliable(packet.kind) != envelope.reliable:
			rejected += 1
			continue
		packets.append(packet)
	return packets

func _valid_envelope(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key: String in ["sender", "target", "socket", "epoch"]:
		if not value.get(key) is String:
			return false
	return accepts(value.sender, value.socket) and value.target == _local and value.epoch == _epoch and \
		value.get("channel") is int and value.get("reliable") is bool and \
		value.channel == (CONTROL_CHANNEL if value.reliable else DATA_CHANNEL) and \
		value.get("bytes") is PackedByteArray and value.bytes.size() <= 1016

static func _reliable(kind: int) -> bool:
	return kind in [NetPacket.Kind.HELLO, NetPacket.Kind.WELCOME, NetPacket.Kind.READY, NetPacket.Kind.BYE]

func close() -> void:
	connected = false
	if _boundary != null:
		_boundary.call("close")
	_boundary = null
	_outbox.clear()
	_fragments.clear()
	_incoming_control.clear()
	_incoming_data.clear()
	_local = ""
	_remote = ""
	_socket = ""
	_epoch = ""

func pending_count() -> int:
	return _outbox.size()
