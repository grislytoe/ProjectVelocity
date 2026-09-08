class_name TrialRecords
extends RefCounted
## Transactional record boundary; failed writes restore the previous in-memory generation.

var store: SaveStore
var definition: TrialMapDefinition
var checksum: String

func _init(owner_store: SaveStore, map: TrialMapDefinition) -> void:
	store = owner_store
	definition = map
	checksum = map.checksum()

func key() -> String:
	return (definition.map_id + ":" + str(definition.map_version) + ":" + checksum \
		+ ":" + str(store.data.profile.uuid)).sha256_text()

func best() -> Dictionary:
	var entry: Variant = store.data.trial_records.get(key(), {})
	if not TrialRecord.valid(entry):
		return {}
	if entry.map_id != definition.map_id or entry.map_version != definition.map_version \
		or entry.checksum != checksum or entry.player_uuid != store.data.profile.uuid:
		return {}
	if entry.ids.size() != definition.checkpoint_ids.size():
		return {}
	for index: int in definition.checkpoint_ids.size():
		if String(entry.ids[index]) != String(definition.checkpoint_ids[index]):
			return {}
	return entry.duplicate(true)

func complete(total: int, splits: Array[int], eligible: bool) -> Dictionary:
	var old: Dictionary = best()
	var result: Dictionary = {"new_pb": false, "saved": false, "previous": old}
	if not eligible or splits.size() != definition.checkpoint_ids.size():
		return result
	var segments: Array[int] = []
	var previous: int = 0
	for stamp: int in splits:
		segments.append(stamp - previous)
		previous = stamp
	segments.append(total - previous)
	var ids: Array[String] = []
	for id: StringName in definition.checkpoint_ids:
		ids.append(String(id))
	var entry: Dictionary = {"map_id": definition.map_id, "map_version": definition.map_version,
		"checksum": checksum, "player_uuid": store.data.profile.uuid, "total": total,
		"ids": ids, "splits": splits.duplicate(), "segments": segments}
	if not TrialRecord.valid(entry):
		return result
	var improved: bool = old.is_empty() or total < int(old.total)
	if not old.is_empty():
		for index: int in segments.size():
			segments[index] = mini(segments[index], int(old.segments[index]))
	if not improved:
		entry = old.duplicate(true)
	entry.segments = segments
	var backup: Dictionary = store.data.duplicate(true)
	store.data.trial_records[key()] = entry
	if not store.save():
		store.data = backup
		return result
	result.new_pb = improved
	result.saved = true
	return result
