class_name NetPacket
extends RefCounted
## JSON values only. No Variant object deserialization or resource paths cross this boundary.

enum Kind { HELLO, WELCOME, READY, INPUT, SNAPSHOT, BYE, PING, PONG }
var kind: Kind = Kind.HELLO
var session: String = ""
var tick: int = 0
var data: Array = []

static func make(type: Kind, scope: String, time: int, payload: Array = []) -> NetPacket:
	var packet := NetPacket.new()
	packet.kind = type
	packet.session = scope
	packet.tick = time
	packet.data = payload.duplicate(true)
	return packet

func encode(config: NetworkConfig) -> PackedByteArray:
	return JSON.stringify([config.protocol, kind, session, tick, data]).to_utf8_buffer()

static func number(value: Variant, limit: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and absf(value) <= limit

static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return number(value, maximum) and value >= minimum and floorf(value) == value

static func vector(value: Variant, limit: float) -> bool:
	return value is Array and value.size() == 2 and number(value[0], limit) and number(value[1], limit)

static func hex(value: Variant, length: int, empty: bool = false) -> bool:
	return value is String and ((empty and value.is_empty()) or (
		value.length() == length and value.is_valid_hex_number(false)))

static func profile(value: Variant) -> bool:
	return value is Array and value.size() == 3 and PlayerProfileData.valid_nickname(value[0]) \
		and hex(value[1], 8) and hex(value[2], 8)

static func decode(bytes: PackedByteArray, config: NetworkConfig) -> NetPacket:
	if bytes.size() > config.max_packet_bytes or bytes.size() < 8:
		return null
	# Reject excessive nesting before parsing to keep parser stack/memory bounded.
	var depth: int = 0
	for byte: int in bytes:
		if byte in [91, 123]:
			depth += 1
			if depth > 12:
				return null
		elif byte in [93, 125]:
			depth -= 1
	var parser := JSON.new()
	if parser.parse(bytes.get_string_from_utf8()) != OK:
		return null
	var value: Variant = parser.data
	if not value is Array or value.size() != 5 or not integer(value[0], config.protocol, config.protocol) \
		or not integer(value[1], 0, Kind.PONG) or not hex(value[2], 32, true) \
		or not integer(value[3], 0, 2147483647) or not value[4] is Array:
		return null
	var type: int = int(value[1])
	var payload: Array = value[4]
	var valid: bool = false
	match type:
		Kind.HELLO:
			valid = payload.size() == 5 and payload[0] is String and payload[0].length() <= 64 \
				and integer(payload[1], 1, 65535) and hex(payload[2], 64) \
				and profile(payload[3]) and hex(payload[4], 32, true)
		Kind.WELCOME:
			valid = payload.size() == 4 and hex(payload[0], 32) \
				and integer(payload[1], 20, 30) and profile(payload[2]) and profile(payload[3])
		Kind.READY:
			valid = payload.size() == 2 and payload[0] is bool and integer(payload[1], 0, 2147483647)
		Kind.BYE:
			valid = payload.is_empty()
		Kind.INPUT:
			valid = InputCommand.decode(payload) != null
		Kind.PING, Kind.PONG:
			valid = payload.size() == 1 and integer(payload[0], 0, 2147483647)
		Kind.SNAPSHOT:
			valid = valid_snapshot(payload)
	if not valid or (type != Kind.HELLO and value[2].is_empty()):
		return null
	return make(type as Kind, value[2], int(value[3]), payload)

static func valid_snapshot(payload: Array) -> bool:
	if payload.size() != 11 or not RaceBaseline.valid(payload[10]) or not integer(payload[0], 0, 65535) \
		or not integer(payload[1], 0, 2147483647) or not integer(payload[2], -1, 2147483647) \
		or not payload[3] is bool or not payload[4] is Array or payload[4].size() != 2 \
		or not payload[5] is Array or payload[5].size() > 256 \
		or not payload[6] is Array or payload[6].size() > 128 \
		or not integer(payload[7], 0, 2) or not integer(payload[8], 0, 2700) \
		or not payload[9] is Array or payload[9].size() != 2 \
		or not integer(payload[9][0], 0, 128) or not integer(payload[9][1], 0, 128):
		return false
	for state: Variant in payload[4]:
		if ActorState.decode(state) == null:
			return false
	for dynamic: Variant in payload[5]:
		if not dynamic is Array or dynamic.size() != 11 or not integer(dynamic[0], 0, 255) \
			or not integer(dynamic[1], 0, 5) or not integer(dynamic[10], 0, 2147483647):
			return false
		for i: int in range(2, 10):
			if not number(dynamic[i], 10000000):
				return false
	for event: Variant in payload[6]:
		if not event is Array or event.size() != 7 or not integer(event[0], 1, 2147483647) \
			or not integer(event[1], 0, 2147483647) or not integer(event[2], 0, 2) \
			or not integer(event[3], 0, GameplayEvents.Kind.LASER_HIT) or not integer(event[4], 0, 65535) \
			or not integer(event[5], 1, 2147483647) or not integer(event[6], 0, 2147483647):
			return false
	return true
