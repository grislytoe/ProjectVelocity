class_name VisualAssetRegistry
extends RefCounted
## Curated IDs only. Save/profile strings are metadata and are never loaded as paths.

const MANIFEST_VERSION := 1
const ENVIRONMENT_IDS: PackedStringArray = ["industrial_foundry_far_v1"]
const COSMETIC_SLOT_IDS: Dictionary = {
	"head": ["", "base_head"],
	"hat": [""],
	"torso": ["", "base_torso"],
	"arms": ["", "base_arms"],
	"legs": ["", "base_legs"],
}


static func create_environment(map_id: String) -> Node2D:
	match map_id:
		"industrial_foundry":
			return IndustrialFoundryBackground.new()
	return null


static func cosmetic_id_registered(slot: String, asset_id: String) -> bool:
	return COSMETIC_SLOT_IDS.has(slot) and asset_id in COSMETIC_SLOT_IDS[slot]


static func environment_source(asset_id: String) -> String:
	if asset_id == "industrial_foundry_far_v1":
		return "res://visuals/environment/industrial_foundry_far.webp"
	return ""
