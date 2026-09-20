extends SceneTree
## NON-LIVE: fixtures verify project policy only, never EOS SDK/service compatibility.

var failures: int = 0
var queries: int = 0
const EPOCH: String = "abcdef123456abcdef123456"

class FakeDatagrams extends RefCounted:
	var incoming: Array = []
	var sent: Array = []
	var blocked: bool = false
	var closed: bool = false
	func is_non_live_fixture() -> bool:
		return true
	func send_datagram(value: Dictionary) -> bool:
		if blocked:
			return false
		sent.append(value.duplicate(true))
		return true
	func receive_datagram() -> Variant:
		return null if incoming.is_empty() else incoming.pop_front()
	func close() -> void:
		closed = true
		incoming.clear()
		sent.clear()

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _entropy(_count: int) -> PackedByteArray:
	return PackedByteArray([0, 1, 2, 3, 4, 5])

func _collision(_code: String) -> int:
	queries += 1
	return 0 if queries == 3 else 1

func _run() -> void:
	check(not Engine.has_singleton("IEOS"), "Ordinary test process never loads native EOS")
	check(JoinCode.ALPHABET.length() == 31, "Explicit nonambiguous alphabet")
	check(JoinCode.normalize("  abc234\n") == "ABC234", "Trim and ASCII case")
	for value: String in ["AB01IO", "АBC234", "ſBC234", "ABC 23", "ABC-23", "ABC23", "ABC2345"]:
		check(JoinCode.normalize(value).is_empty(), "Reject malformed code")
	check(JoinCode.generate(_entropy) == "ABCDEF", "Deterministic test entropy")
	check(JoinCode.reserve_candidate(_collision, _entropy) == "ABCDEF" and queries == 3, "Collision retries")
	queries = 0
	check(JoinCode.reserve_candidate(func(_c: String) -> int: queries += 1; return 1, _entropy).is_empty()
		and queries == 8, "Collision exhaustion is bounded")
	check(JoinCode.reserve_candidate(func(_c: String) -> int: return -1, _entropy).is_empty(), "Search failure never free")
	check(JoinCode.generate(func(_n: int) -> PackedByteArray: return PackedByteArray([255, 254, 253])).is_empty(), "Reject biased tail/entropy failure")
	for i: int in 100:
		var value: String = JoinCode.generate()
		check(value.length() == 6 and JoinCode.normalize(value) == value, "Crypto format; no global uniqueness claim")
	_identity()
	_lobby()
	_transport()
	check(not EOSCapability.live_enabled(), "Native gate cannot be enabled by credentials alone")
	if failures == 0:
		print("PROJECTVELOCITY_M19_POLICY_OK live=false native=false")
	quit(0 if failures == 0 else 1)

func _identity() -> void:
	var service := OnlineService.new()
	check(service.begin(false, true, true, 0) == -1, "Explicit opt-in")
	check(service.begin(true, false, true, 0) == -1, "Config before platform")
	check(service.begin(true, true, false, 0) == -1, "Missing real boundary")
	var epoch: int = service.begin(true, true, true, 0)
	service.connect_result(epoch, true, true, false)
	check(service.state == OnlineService.State.AUTH, "Connect cannot skip Auth")
	service.auth_result(epoch, true, true, false)
	check(service.state == OnlineService.State.CONNECT, "Account identity is not a PUID")
	service.connect_result(epoch, false, false, true)
	check(service.state == OnlineService.State.LINK_REQUIRED, "No auto create/link/device identity")
	service.logout()
	service.connect_result(epoch, true, true, false)
	check(service.state == OnlineService.State.OFFLINE, "Cancelled callbacks cannot revive identity")
	epoch = service.begin(true, true, true, 0)
	service.auth_result(epoch, true, true, false)
	service.connect_result(epoch, true, true, false)
	check(service.state == OnlineService.State.ONLINE, "Non-live state transition")
	service.logout()
	service.begin(true, true, true, 10)
	service.poll(30010)
	check(service.state == OnlineService.State.FAILED and service.error_key == "EOS_TIMEOUT", "Bounded timeout")
	service.shutdown()
	check(service.begin(true, true, true, 0) == -1, "Global shutdown terminal")

func _lobby() -> void:
	var expected: Dictionary = LobbyPolicy.metadata("ABC234", MapCatalog.official()[0])
	var row: Dictionary = {"handle": "fixture-room", "capacity": 2, "members": 1,
		"open": true, "owner_present": true, "metadata": expected}
	check(LobbyPolicy.select([row], expected).error.is_empty(), "Exactly one compatible result")
	check(LobbyPolicy.select([], expected).error == "EOS_NOT_FOUND", "Zero result")
	check(LobbyPolicy.select([row, row], expected).error == "EOS_CODE_AMBIGUOUS", "Duplicate handle rejected")
	var other: Dictionary = row.duplicate(true)
	other.handle = "fixture-other"
	check(LobbyPolicy.select([row, other], expected).error == "EOS_CODE_AMBIGUOUS", "Concurrent code collision")
	check(LobbyPolicy.select([row], expected, false).error == "EOS_SEARCH_FAILED", "Truncated search rejected")
	for key: String in LobbyPolicy.KEYS:
		other = row.duplicate(true)
		other.metadata[key] = null
		check(LobbyPolicy.select([other], expected).error == "EOS_NOT_FOUND", "Strict metadata field")
	for field: String in ["capacity", "members", "open", "owner_present"]:
		other = row.duplicate(true)
		other[field] = 3 if field in ["capacity", "members"] else false
		check(LobbyPolicy.select([other], expected).error == "EOS_NOT_FOUND", "Full/stale/invalid result")
	var service := LobbyService.new()
	var epoch: int = service.begin_search(expected, 0)
	check(service.search_result(epoch, [row]) == row.handle, "Narrow search handle")
	check(not service.admission_result(epoch, row.handle, expected, 3, true, 2, true), "Join race cannot admit third player")
	service.leave()
	epoch = service.begin_create(expected, 0)
	check(not service.admission_result(epoch, row.handle, expected, 1, true, 2, false), "No code before published metadata")
	service.leave()
	epoch = service.begin_create(expected, 0)
	check(service.admission_result(epoch, row.handle, expected, 1, true, 2, true), "Non-live create acknowledgement")
	check(service.code == "ABC234", "Display code only after publication")
	check(not service.membership_changed(false, 1) and service.code.is_empty(), "Host loss closes code; no promotion")
	epoch = service.begin_search(expected, 0)
	service.leave()
	check(service.search_result(epoch, [row]).is_empty(), "Cancel invalidates search")
	service.begin_search(expected, 0)
	service.poll(15000)
	check(service.error_key == "EOS_TIMEOUT", "Lobby timeout")

func _transport() -> void:
	var host := EOSP2PTransport.new()
	check(host.open() == ERR_UNAVAILABLE, "Production native path stays blocked")
	var client := EOSP2PTransport.new()
	var a := FakeDatagrams.new()
	var b := FakeDatagrams.new()
	check(host.attach_test_boundary(a, ["fixture-a", "fixture-b"], "fixture-a", EPOCH) == OK, "Attach non-live host")
	check(client.attach_test_boundary(b, ["fixture-a", "fixture-b"], "fixture-b", EPOCH) == OK, "Attach non-live guest")
	check(not host.accepts("fixture-third", "PV19" + EPOCH), "Unknown member request denied")
	var packet: NetPacket = NetPacket.make(NetPacket.Kind.PING, "a".repeat(32), 0, [0])
	host.send(packet)
	host.poll(0)
	check(a.sent.size() == 1, "Framed datagram emitted")
	var valid: Dictionary = a.sent[0].duplicate(true)
	b.incoming.append(valid)
	check(client.poll(1).size() == 1, "Non-live packet reaches existing codec")
	for key: String in ["sender", "socket", "epoch", "channel", "bytes", "reliable"]:
		var invalid: Dictionary = valid.duplicate(true)
		match key:
			"channel": invalid[key] = 99
			"bytes": invalid[key] = PackedByteArray([1, 2])
			"reliable": invalid[key] = true
			_: invalid[key] = "foreign"
		b.incoming.append(invalid)
		var before: int = client.rejected
		check(client.poll(2).is_empty() and client.rejected > before, "Reject invalid authenticated envelope")
	var oversized: Dictionary = valid.duplicate(true)
	var huge := PackedByteArray()
	huge.resize(1017)
	oversized.bytes = huge
	b.incoming.append(oversized)
	var rejects: int = client.rejected
	check(client.poll(3).is_empty() and client.rejected == rejects + 1, "Oversize envelope before reassembly")
	host.send(NetPacket.make(NetPacket.Kind.BYE, "a".repeat(32), 0))
	host.poll(4)
	var control: Dictionary = a.sent[-1]
	check(control.channel == 1 and control.reliable, "Reliable control channel")
	b.incoming.append(control)
	check(client.poll(4).size() == 1, "Reliable control codec path")
	for i: int in 200:
		b.incoming.append({})
	client.poll(5)
	check(b.incoming.size() == 72, "Receive work cap")
	a.blocked = true
	for i: int in 300:
		host.send(packet)
	check(host.pending_count() == 256 and host.error == "EOS_BACKPRESSURE", "Bounded whole-message backpressure")
	host.close()
	client.close()
	check(host.pending_count() == 0 and a.closed and b.closed and not host.connected, "Queue/boundary teardown")
	var fresh := FakeDatagrams.new()
	client.attach_test_boundary(fresh, ["fixture-a", "fixture-b"], "fixture-b", "b".repeat(24))
	fresh.incoming.append(valid)
	check(client.poll(6).is_empty(), "Old epoch packet rejected after reconnect")
	client.close()
	check(client.attach_test_boundary(FakeDatagrams.new(), ["fixture-a", "fixture-a"], "fixture-a", EPOCH) != OK, "No duplicate identity")
