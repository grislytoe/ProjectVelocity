class_name MatchSettings
extends RefCounted
## Detached v1 settings; playlist/modifier fields reserve a future versioned extension.

var map_id: String = ""
var rounds: int = 3
var playlist: Array[String] = []
var modifiers: Dictionary = {}

func copy() -> MatchSettings:
	var result := MatchSettings.new()
	result.map_id = map_id
	result.rounds = rounds
	result.playlist.assign(playlist)
	result.modifiers = modifiers.duplicate(true)
	return result

func valid(maps: Array[MapDefinition]) -> bool:
	if rounds < 1 or rounds > 10 or not playlist.is_empty() or not modifiers.is_empty():
		return false
	for map: MapDefinition in maps:
		if map != null and map.map_id == map_id:
			return true
	return false
