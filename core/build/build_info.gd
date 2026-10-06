class_name BuildInfo
extends RefCounted
## Build identity. Release flags come from the engine, never a user-writable setting.

const VERSION: String = "0.25.0-rc.1"
const BUILD_NUMBER: int = 31
## Wire compatibility identity; increment when incompatible network changes are introduced.
const NETWORK_PROTOCOL_VERSION: int = 5
const NETWORK_WIRE_REVISION: int = 4
const MILESTONE: String = "M25"
## Candidate identity is separate from gameplay wire compatibility; see M18 gate report.
const EOSG_CANDIDATE: String = "2.3.0"
const REQUIRED_ENGINE: String = "4.7.2"


static func is_development() -> bool:
	return OS.is_debug_build()


static func channel() -> String:
	if OS.has_feature("staging"):
		return "STAGING"
	return "DEV" if is_development() else "RELEASE"


static func source_sha() -> String:
	var provenance: BuildProvenance = load(
		"res://core/build/source_provenance.tres") as BuildProvenance
	if provenance == null:
		return "UNEMBEDDED"
	return provenance.validated_source_sha()


static func label() -> String:
	return "%s | %s | build %d" % [VERSION, channel(), BUILD_NUMBER]
