class_name PlayerProfileData
extends RefCounted
## Persistent identity and presentation data. Nicknames are never network identity.

var uuid: String
var nickname: String = "Player"
var body_color: String = "44cceeff"
var accent_color: String = "ffffffff"
var cosmetic_slots: Dictionary = {"head": "", "hat": "", "torso": "", "arms": "", "legs": ""}
var language: String = "en"
var last_input_device: String = "keyboard_mouse"
var created_at: int
var last_launch_at: int


static func new_uuid() -> String:
	var bytes: PackedByteArray = Crypto.new().generate_random_bytes(16)
	if bytes.size() != 16:
		return ""
	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80
	var hex: String = bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8), hex.substr(8, 4), hex.substr(12, 4),
		hex.substr(16, 4), hex.substr(20, 12)]


static func create() -> PlayerProfileData:
	var profile := PlayerProfileData.new()
	profile.uuid = new_uuid()
	profile.created_at = int(Time.get_unix_time_from_system())
	profile.last_launch_at = profile.created_at
	return profile


static func valid_nickname(value: Variant) -> bool:
	if not value is String or value.length() < 3 or value.length() > 15:
		return false
	if value.strip_edges().is_empty():
		return false
	for index: int in value.length():
		var code: int = value.unicode_at(index)
		var latin: bool = (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
		var cyrillic: bool = (code >= 0x0400 and code <= 0x0481) or (
			code >= 0x048a and code <= 0x04ff)
		if not (latin or cyrillic or (code >= 48 and code <= 57) or code in [32, 45, 95]):
			return false
	return true


static func matches(value: Variant, pattern: String) -> bool:
	if not value is String:
		return false
	var regex := RegEx.new()
	if regex.compile(pattern) != OK:
		return false
	var found: RegExMatch = regex.search(value)
	return found != null and found.get_string() == value


static func is_whole_number(value: Variant, minimum: int = 0) -> bool:
	if not (value is int or value is float):
		return false
	return is_finite(float(value)) and float(value) >= minimum and (
		float(value) <= 9007199254740991.0 and floor(float(value)) == float(value))


static func validate(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	if not matches(value.get("uuid"), "^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"):
		return false
	if not valid_nickname(value.get("nickname")):
		return false
	for field: String in ["body_color", "accent_color"]:
		if not matches(value.get(field), "^[0-9a-f]{8}$"):
			return false
	if value.get("language") not in ["en", "ru"]:
		return false
	if value.get("last_input_device") not in ["keyboard_mouse", "controller"]:
		return false
	if not is_whole_number(value.get("created_at"), 1) or not is_whole_number(
		value.get("last_launch_at"), 1):
		return false
	if value.last_launch_at < value.created_at:
		return false
	var slots: Variant = value.get("cosmetic_slots")
	if not slots is Dictionary:
		return false
	for slot: String in ["head", "hat", "torso", "arms", "legs"]:
		if not slots.has(slot):
			return false
	for slot: Variant in slots:
		if not slot is String or not slots[slot] is String or slots[slot].length() > 128:
			return false
	return true


func to_dictionary() -> Dictionary:
	return {
		"uuid": uuid, "nickname": nickname, "body_color": body_color,
		"accent_color": accent_color, "cosmetic_slots": cosmetic_slots.duplicate(true),
		"language": language, "last_input_device": last_input_device,
		"created_at": created_at, "last_launch_at": last_launch_at,
	}


static func from_dictionary(value: Dictionary) -> PlayerProfileData:
	if not validate(value):
		return null
	var profile := PlayerProfileData.new()
	profile.uuid = value.uuid
	profile.nickname = value.nickname
	profile.body_color = value.body_color
	profile.accent_color = value.accent_color
	profile.cosmetic_slots = value.cosmetic_slots.duplicate(true)
	profile.language = value.language
	profile.last_input_device = value.last_input_device
	profile.created_at = int(value.created_at)
	profile.last_launch_at = int(value.last_launch_at)
	return profile
