class_name MapDefinition
extends Resource
## Local authoring contract. Values are immutable for the lifetime of a loaded map.

@export var map_id: String = ""
@export var map_version: int = 0
@export var name_key: String = ""
@export var description_key: String = ""
@export var scene_path: String = "res://gameplay/race/solo_course.tscn"
@export var preview: Texture2D
@export_enum("official", "custom") var map_type: String = "custom"
@export var difficulty_key: String = "UI_NORMAL"
@export var expected_duration_seconds: int = 0
@export var par_time_ticks: int = 0
@export var death_bounds: Rect2
@export var camera_bounds: CameraBounds
@export var camera_zones: Array[CameraZone] = []
## Godot 2D world pixels. Placement origins/major geometry use this configurable lattice.
@export var grid_pixels: Vector2 = Vector2(20, 20)
@export var sections: Array[MapSectionPlacement] = []
@export var start: MapPoint
@export var finish: MapPoint
@export var checkpoints: Array[MapPoint] = []
@export var strict_order: bool = true
@export var declared_checksum: String = ""

var checkpoint_ids: Array[StringName]:
	get:
		var ids: Array[StringName] = []
		for point: MapPoint in checkpoints:
			if point != null:
				ids.append(point.point_id)
		return ids

var mandatory_ids: Array[StringName]:
	get:
		var ids: Array[StringName] = []
		for point: MapPoint in checkpoints:
			if point != null and point.mandatory:
				ids.append(point.point_id)
		return ids

func checksum() -> String:
	return MapChecksum.compute(self)

func compatible_with(other: MapDefinition) -> bool:
	if other == null or map_id != other.map_id or map_version != other.map_version:
		return false
	var own: String = checksum()
	var theirs: String = other.checksum()
	return not own.is_empty() and own == declared_checksum and theirs == other.declared_checksum \
		and own == theirs
