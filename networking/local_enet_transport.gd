class_name LocalENetTransport
extends MultiplayerTransport
## The only ENet dependency. Loopback-only developer adapter, one guest, no RPC objects.

var _peer: ENetMultiplayerPeer
var _host: bool = false
var _remote: int = 0
var _fragments := PacketFragments.new()

func open(host: bool, port: int) -> Error:
	close()
	_host = host
	_peer = ENetMultiplayerPeer.new()
	_peer.set_bind_ip("127.0.0.1")
	_peer.peer_connected.connect(_joined)
	_peer.peer_disconnected.connect(_left)
	var result: Error = _peer.create_server(port, 1, 1) if host else (
		_peer.create_client("127.0.0.1", port, 1))
	if result != OK:
		error = "Local transport open failed: %d" % result
	return result

func _joined(id: int) -> void:
	_fragments.clear()
	_remote = id
	connected = true

func _left(_id: int) -> void:
	_fragments.clear()
	connected = false
	_remote = 0

func send(packet: NetPacket) -> void:
	if not connected or _peer == null:
		return
	_peer.set_target_peer(_remote)
	# ENet may throttle unreliable traffic under scheduler-induced RTT variance even
	# on loopback. Control intent must survive that throttle; application shaping
	# still drops decoded controls and exercises the existing idempotent retries.
	_peer.transfer_mode = MultiplayerPeer.TRANSFER_MODE_RELIABLE if packet.kind in [
		NetPacket.Kind.HELLO, NetPacket.Kind.WELCOME, NetPacket.Kind.READY, NetPacket.Kind.BYE
	] else MultiplayerPeer.TRANSFER_MODE_UNRELIABLE
	_peer.transfer_channel = 0
	var bytes: PackedByteArray = packet.encode(config)
	if bytes.size() <= config.max_packet_bytes:
		for fragment: PackedByteArray in _fragments.split(bytes):
			_peer.put_packet(fragment)

func poll(tick: int) -> Array[NetPacket]:
	var packets: Array[NetPacket] = []
	if _peer == null:
		return packets
	_peer.poll()
	_fragments.prune(tick)
	if not _host and _peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		connected = false
	# Bound receive work as well as command admission; excess stays outside simulation.
	for i: int in mini(_peer.get_available_packet_count(), 128):
		var sender: int = _peer.get_packet_peer()
		var datagram: PackedByteArray = _peer.get_packet()
		if sender != _remote:
			rejected += 1
			continue
		var before: int = _fragments.rejected
		var bytes: PackedByteArray = _fragments.join(datagram, tick)
		rejected += _fragments.rejected - before
		if bytes.is_empty():
			continue
		var packet: NetPacket = NetPacket.decode(bytes, config)
		if packet == null:
			rejected += 1
			error = "Rejected malformed or incompatible wire packet"
		else:
			packets.append(packet)
	return packets

func close() -> void:
	if _peer != null:
		_peer.close()
		_peer = null
	_remote = 0
	connected = false
	_fragments.clear()
