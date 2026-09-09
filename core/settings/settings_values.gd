class_name SettingsValues
extends RefCounted
## Presentation-only additions to the legacy settings document.

const BUSES: Array[String] = ["Master", "Music", "SFX", "UI", "Ambience"]
const FPS: Array[int] = [30, 60, 90, 120, 144, 165, 240, 0]
const CORRECTIONS: Array[String] = ["off", "protanopia", "deuteranopia", "tritanopia"]
const PRESETS: Dictionary = {
	"quality": {"filter": Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "segments": 48, "effects": 1.0, "antialias": true},
	"balanced": {"filter": Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR, "segments": 32, "effects": 0.75, "antialias": true},
	"performance": {"filter": Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR, "segments": 16, "effects": 0.5, "antialias": false},
}

static func extend(settings: Dictionary) -> void:
	settings.video.merge({"post_intensity": 1.0, "speed_intensity": 1.0})
	settings.audio.merge({"mutes": {"master": false, "music": false, "sfx": false,
		"ui": false, "ambience": false}})
	settings.accessibility.merge({"disable_strong_flashes": false,
		"colorblind": "off", "text_size": 1.0})

static func valid(settings: Dictionary) -> bool:
	for key: String in ["post_intensity", "speed_intensity"]:
		if not SaveSchema.number_in(settings.video.get(key), 0, 1):
			return false
	if not settings.audio.get("mutes") is Dictionary:
		return false
	for bus: String in BUSES:
		if not settings.audio.mutes.get(bus.to_lower()) is bool:
			return false
	var access: Dictionary = settings.accessibility
	return access.get("disable_strong_flashes") is bool and access.get("colorblind") is String and (
		access.get("colorblind") in CORRECTIONS) and SaveSchema.number_in(
		access.get("text_size"), 0.75, 1.5)

static func defaults() -> Dictionary:
	return SaveSchema.defaults().settings.duplicate(true)

static func copy_known(target: Dictionary, source: Dictionary, template: Dictionary) -> void:
	for key: String in template:
		if template[key] is Dictionary and not template[key].is_empty():
			copy_known(target[key], source[key], template[key])
		else:
			target[key] = source[key].duplicate(true) if source[key] is Dictionary or source[key] is Array else source[key]
