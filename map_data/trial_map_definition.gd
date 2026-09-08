class_name TrialMapDefinition
extends Resource

@export var map_id: String = "solo_training"
@export var map_version: int = 1
@export var name_key: String = "TT_MAP"
@export var scene_path: String = "res://gameplay/race/solo_course.tscn"
@export var checkpoint_ids: Array[StringName] = [&"a", &"b"]

# Baked from normalized gameplay sources by dev_tools/check_trial_hash.ps1.
# Stable between editor and exported PCK; validator rejects a stale manifest.
const CONTENT_HASH: String = "0832bd598cd2e34e22ca69967a1204871f89393d241386f46db1735606ef2072"

func checksum() -> String:
	return (CONTENT_HASH + ":" + scene_path + ":" + JSON.stringify(checkpoint_ids)).sha256_text()
