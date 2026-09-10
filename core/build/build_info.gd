class_name BuildInfo
extends RefCounted
## Build identity. Release flags come from the engine, never a user-writable setting.

const VERSION: String = "0.14.0-dev"
const BUILD_NUMBER: int = 18
## Wire compatibility identity; increment when incompatible network changes are introduced.
const NETWORK_PROTOCOL_VERSION: int = 1
const MILESTONE: String = "M14"
const REQUIRED_ENGINE: String = "4.7.2"


static func is_development() -> bool:
	return OS.is_debug_build()


static func channel() -> String:
	if OS.has_feature("staging"):
		return "STAGING"
	return "DEV" if is_development() else "RELEASE"


static func label() -> String:
	return "%s | %s | build %d" % [VERSION, channel(), BUILD_NUMBER]
