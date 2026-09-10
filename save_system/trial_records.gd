class_name TrialRecords
extends RefCounted
## Transactional record boundary; failed writes restore the previous in-memory generation.

var store: SaveStore
var definition: MapDefinition
var checksum: String

func _init(owner_store: SaveStore, map: MapDefinition) -> void:
	store = owner_store
	definition = map
	checksum = map.checksum() if map != null else ""

func key() -> String:
	return (definition.map_id + ":" + str(definition.map_version) + ":" + checksum \
		+ ":" + str(store.data.profile.uuid)).sha256_text()

func best() -> Dictionary:
	if definition == null or checksum.is_empty():
		return {}
	var entry: Variant = store.data.trial_records.get(key(), {})
	if not TrialRecord.valid(entry):
		return {}
	if entry.map_id != definition.map_id or entry.map_version != definition.map_version \
		or entry.checksum != checksum or entry.player_uuid != store.data.profile.uuid:
		return {}
	if not _valid_route(entry.ids):
		return {}
	return entry.duplicate(true)

func _valid_route(ids: Array) -> bool:
	var progress := CheckpointProgress.new()
	if not progress.configure(definition.checkpoint_ids, definition.mandatory_ids, definition.strict_order):
		return false
	for id: Variant in ids:
		if not id is String and not id is StringName:
			return false
		if not progress.activate(StringName(id)):
			return false
	return progress.can_finish()

func complete(total: int, splits: Array[int], eligible: bool, reached: Variant = null) -> Dictionary:
	var old: Dictionary = best()
	var result: Dictionary = {"new_pb": false, "saved": false, "previous": old}
	if definition == null or (reached != null and not reached is Array):
		return result
	var route: Array = definition.checkpoint_ids if reached == null else reached
	if not eligible or checksum.is_empty() or splits.size() != route.size() or not _valid_route(route):
		return result
	var segments: Array[int] = []
	var previous: int = 0
	for stamp: int in splits:
		segments.append(stamp - previous)
		previous = stamp
	segments.append(total - previous)
	var ids: Array[String] = []
	for id: StringName in route:
		ids.append(String(id))
	var entry: Dictionary = {"map_id": definition.map_id, "map_version": definition.map_version,
		"checksum": checksum, "player_uuid": store.data.profile.uuid, "total": total,
		"ids": ids, "splits": splits.duplicate(), "segments": segments}
	if not TrialRecord.valid(entry):
		return result
	var improved: bool = old.is_empty() or total < int(old.total)
	# Segment minima compare only identical routes; total PB still compares valid finishes.
	if not old.is_empty() and old.ids == ids:
		for index: int in segments.size():
			segments[index] = mini(segments[index], int(old.segments[index]))
	if not improved:
		entry = old.duplicate(true)
		if old.ids != ids:
			segments = Array(old.segments, TYPE_INT, "", null)
	entry.segments = segments
	var backup: Dictionary = store.data.duplicate(true)
	store.data.trial_records[key()] = entry
	if not store.save():
		store.data = backup
		return result
	result.new_pb = improved
	result.saved = true
	return result
