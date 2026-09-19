class_name LobbyPolicy
extends RefCounted
## Detached service rows, never raw EOS callbacks. No ready/round metadata grants authority.

const CAPACITY: int = 2
const MAX_RESULTS: int = 25
const KEYS: Array[String] = ["code", "game", "protocol", "wire", "build", "map",
	"map_version", "checksum"]

static func metadata(code: String, map: MapDefinition) -> Dictionary:
	if map == null or JoinCode.normalize(code) != code or code.is_empty():
		return {}
	return {"code": code, "game": "ProjectVelocity", "protocol": BuildInfo.NETWORK_PROTOCOL_VERSION,
		"wire": BuildInfo.NETWORK_WIRE_REVISION, "build": BuildInfo.VERSION,
		"map": map.map_id, "map_version": map.map_version, "checksum": map.checksum()}

static func compatible(value: Variant, expected: Dictionary) -> bool:
	if not value is Dictionary or value.size() != KEYS.size() or expected.size() != KEYS.size():
		return false
	if not valid_metadata(value) or not valid_metadata(expected):
		return false
	for key: String in KEYS:
		if not value.has(key) or not expected.has(key) or typeof(value[key]) != typeof(expected[key]):
			return false
		if value[key] != expected[key]:
			return false
	return true

static func valid_metadata(value: Dictionary) -> bool:
	for key: String in ["code", "game", "build", "map", "checksum"]:
		if not value.get(key) is String or value[key].is_empty() or value[key].length() > 64:
			return false
	for key: String in ["protocol", "wire", "map_version"]:
		if not value.get(key) is int or value[key] < 1 or value[key] > 65535:
			return false
	return JoinCode.normalize(value.code) == value.code and value.code.length() == 6 and \
		value.game == "ProjectVelocity" and NetPacket.hex(value.checksum, 64)

static func select(rows: Array, expected: Dictionary, complete: bool = true) -> Dictionary:
	# Refuse truncated searches: one visible match cannot prove absence of duplicates.
	if not complete or rows.size() > MAX_RESULTS:
		return {"error": "EOS_SEARCH_FAILED"}
	var candidates: Dictionary = {}
	var seen: Dictionary = {}
	for row: Variant in rows:
		if not row is Dictionary or not row.get("handle") is String or row.handle.is_empty():
			return {"error": "EOS_SEARCH_FAILED"}
		if seen.has(row.handle):
			return {"error": "EOS_CODE_AMBIGUOUS"}
		seen[row.handle] = true
		if not row.get("capacity") is int or row.capacity != CAPACITY:
			continue
		if not row.get("members") is int or row.members != 1:
			continue
		if not row.get("open") is bool or not row.get("owner_present") is bool or \
			not row.open or not row.owner_present:
			continue
		if compatible(row.get("metadata"), expected):
			candidates[row.handle] = row
	if candidates.size() > 1:
		return {"error": "EOS_CODE_AMBIGUOUS"}
	if candidates.is_empty():
		return {"error": "EOS_NOT_FOUND"}
	return {"error": "", "row": candidates.values()[0].duplicate(true)}
