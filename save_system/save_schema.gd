class_name SaveSchema
extends RefCounted
## Pure schema validation and sequential migrations. No filesystem access.

const CURRENT_VERSION: int = 2
const MIGRATIONS: Dictionary = {0: "_migrate_v0_to_v1", 1: "_migrate_v1_to_v2"}


static func defaults() -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"profile": PlayerProfileData.create().to_dictionary(),
		"settings": {
			"video": {"resolution": [1920, 1080], "window_mode": "windowed", "vsync": true,
				"fps_limit": 60, "effects_quality": "balanced"},
			"audio": {"master": 1.0, "music": 1.0, "sfx": 1.0, "ui": 1.0, "ambience": 1.0},
			"controls": {"bindings": {}, "input": InputBindings.configuration()},
			"accessibility": {"high_contrast": false, "flash_intensity": 1.0,
				"screen_shake": 0.5, "ui_scale": 1.0, "hud_opacity": 1.0},
		},
		"time_trial_records": {},
		"checkpoint_splits": {},
		"last_lobby_settings": {"round_count": 1, "map_id": ""},
	}


static func decode(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {"status": "invalid"}
	var version: Variant = value.get("save_version")
	if not PlayerProfileData.is_whole_number(version):
		return {"status": "invalid"}
	if version > CURRENT_VERSION:
		return {"status": "unsupported"}
	var data: Dictionary = value.duplicate(true)
	var migrated: bool = false
	while int(data.save_version) < CURRENT_VERSION:
		var previous: int = int(data.save_version)
		if not MIGRATIONS.has(previous):
			return {"status": "unsupported"}
		var schema := SaveSchema.new()
		var next: Variant = schema.call(MIGRATIONS[previous], data)
		if not next is Dictionary or next.get("save_version") != previous + 1:
			return {"status": "invalid"}
		data = next
		migrated = true
	if not validate(data):
		return {"status": "invalid"}
	return {"status": "valid", "data": data, "migrated": migrated}


func _migrate_v0_to_v1(source: Dictionary) -> Dictionary:
	# Version 0 is a documented pre-release fixture, never a shipped user schema.
	# It has the same shape as v1 except it lacks last_lobby_settings.
	var result: Dictionary = source.duplicate(true)
	if result.has("last_lobby_settings"):
		return {}
	result["last_lobby_settings"] = {"round_count": 1, "map_id": ""}
	result["save_version"] = 1
	return result


static func number_in(value: Variant, low: float, high: float) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and (
		float(value) >= low and float(value) <= high)


func _migrate_v1_to_v2(source: Dictionary) -> Dictionary:
	var result: Dictionary = source.duplicate(true)
	if not result.get("settings") is Dictionary or not result.settings.get("controls") is Dictionary:
		return {}
	# Keep the M1 serialized binding foundation verbatim; M2 uses explicit device profiles.
	if not result.settings.controls.has("input"):
		result.settings.controls["input"] = InputBindings.configuration()
	result.save_version = 2
	return result


static func validate(data: Dictionary) -> bool:
	if not PlayerProfileData.is_whole_number(data.get("save_version")) or (
		data.save_version != CURRENT_VERSION):
		return false
	if not PlayerProfileData.validate(data.get("profile")):
		return false
	var settings: Variant = data.get("settings")
	if not settings is Dictionary:
		return false
	for group: String in ["video", "audio", "controls", "accessibility"]:
		if not settings.get(group) is Dictionary:
			return false
	var video: Dictionary = settings.video
	var resolution: Variant = video.get("resolution")
	if not resolution is Array or resolution.size() != 2:
		return false
	for dimension: Variant in resolution:
		if not PlayerProfileData.is_whole_number(dimension, 320) or dimension > 16384:
			return false
	if video.get("window_mode") not in ["windowed", "fullscreen", "borderless"]:
		return false
	if not video.get("vsync") is bool:
		return false
	if not PlayerProfileData.is_whole_number(video.get("fps_limit")) or (
		int(video.fps_limit) not in [0, 30, 60, 90, 120, 144, 165, 240]):
		return false
	if video.get("effects_quality") not in ["quality", "balanced", "performance"]:
		return false
	for bus: String in ["master", "music", "sfx", "ui", "ambience"]:
		if not number_in(settings.audio.get(bus), 0.0, 1.0):
			return false
	var bindings: Variant = settings.controls.get("bindings")
	if not InputBindings.valid_config(settings.controls.get("input")):
		return false
	if not bindings is Dictionary:
		return false
	for action: Variant in bindings:
		if not action is String or action.is_empty() or not bindings[action] is Array:
			return false
		for binding: Variant in bindings[action]:
			if not binding is String or binding.length() > 128:
				return false
	var access: Dictionary = settings.accessibility
	if not access.get("high_contrast") is bool:
		return false
	for field: String in ["flash_intensity", "screen_shake"]:
		if not number_in(access.get(field), 0.0, 1.0):
			return false
	if not number_in(access.get("ui_scale"), 0.5, 2.0) or not number_in(
		access.get("hud_opacity"), 0.5, 1.0):
		return false
	if not _validate_records(data.get("time_trial_records")) or not _validate_splits(
		data.get("checkpoint_splits")):
		return false
	var lobby: Variant = data.get("last_lobby_settings")
	if not lobby is Dictionary:
		return false
	return PlayerProfileData.is_whole_number(lobby.get("round_count"), 1) and (
		lobby.round_count <= 10 and lobby.get("map_id") is String and lobby.map_id.length() <= 128)


static func _validate_records(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for map_id: Variant in value:
		if not map_id is String or map_id.is_empty() or not value[map_id] is Dictionary:
			return false
		var record: Dictionary = value[map_id]
		if not PlayerProfileData.is_whole_number(record.get("best_time_ms"), 1):
			return false
	return true


static func _validate_splits(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for map_id: Variant in value:
		if not map_id is String or map_id.is_empty() or not value[map_id] is Dictionary:
			return false
		for kind: String in ["pb_run_ms", "best_segment_ms"]:
			var times: Variant = value[map_id].get(kind)
			if not times is Array:
				return false
			for time: Variant in times:
				if not PlayerProfileData.is_whole_number(time):
					return false
	return true
