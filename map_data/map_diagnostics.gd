class_name MapDiagnostics
extends RefCounted
## Developer detail stays out of localized player-facing errors.

var errors: Array[Dictionary] = []

func add(code: String, location: String, detail: String) -> void:
	errors.append({"code": code, "location": location, "detail": detail})

func valid() -> bool:
	return errors.is_empty()

func message_key() -> String:
	for error: Dictionary in errors:
		if error.code == "checksum":
			return "MAP_CHECKSUM_ERROR"
	return "MAP_INVALID"

func describe() -> String:
	var lines: PackedStringArray = []
	for error: Dictionary in errors:
		lines.append("%s [%s]: %s" % [error.location, error.code, error.detail])
	return "\n".join(lines)
