class_name TrialRecord
extends RefCounted
## Persist integer 60 Hz timestamps. Presentation alone rounds to milliseconds.

const MAX_TICKS: int = 60 * 60 * 24 * 60

static func valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for field: String in ["map_id", "checksum", "player_uuid"]:
		if not value.get(field) is String or value[field].is_empty():
			return false
	if not PlayerProfileData.matches(value.checksum, "^[0-9a-f]{64}$"):
		return false
	if not PlayerProfileData.matches(value.player_uuid,
		"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"):
		return false
	if not PlayerProfileData.is_whole_number(value.get("map_version"), 1):
		return false
	if not ticks(value.get("total")) or value.total == 0:
		return false
	if not value.get("ids") is Array or not value.get("splits") is Array \
		or not value.get("segments") is Array:
		return false
	if value.ids.size() != value.splits.size() or value.segments.size() != value.ids.size() + 1:
		return false
	var previous: int = 0
	var unique: Array = []
	for index: int in value.ids.size():
		var id: Variant = value.ids[index]
		var stamp: Variant = value.splits[index]
		if not id is String or id.is_empty() or id in unique or not ticks(stamp):
			return false
		if stamp < previous or stamp > value.total:
			return false
		unique.append(id)
		previous = int(stamp)
	previous = 0
	for index: int in value.segments.size():
		var segment: Variant = value.segments[index]
		var end: int = int(value.total) if index == value.splits.size() else int(value.splits[index])
		if not ticks(segment) or segment > end - previous:
			return false
		previous = end
	return true

static func ticks(value: Variant) -> bool:
	return PlayerProfileData.is_whole_number(value) and value <= MAX_TICKS

static func format_time(value: int) -> String:
	var ms: int = roundi(float(absi(value)) * 1000.0 / 60.0)
	return "%02d:%02d.%03d" % [ms / 60000, (ms / 1000) % 60, ms % 1000]

static func delta(value: int) -> String:
	return ("+" if value >= 0 else "−") + format_time(value)
