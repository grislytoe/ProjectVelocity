class_name EOSCapability
extends RefCounted
## Presence is not validation, entitlement, reachability or redistribution clearance.
## No extension load, account lookup or service call on ordinary startup.

const REQUIRED: Array[String] = ["PV_EOS_PRODUCT_ID", "PV_EOS_SANDBOX_ID",
	"PV_EOS_DEPLOYMENT_ID", "PV_EOS_CLIENT_ID", "PV_EOS_CLIENT_SECRET",
	"PV_EOS_DEV_AUTH_ENDPOINT", "PV_EOS_DEV_AUTH_NAME_A", "PV_EOS_DEV_AUTH_NAME_B",
	"PV_EOS_SDK_ARCHIVE"]

static func presence() -> Dictionary:
	var result: Dictionary = {}
	for name_value: String in REQUIRED:
		result[name_value] = not OS.get_environment(name_value).strip_edges().is_empty()
	return result

static func unavailable_key() -> String:
	return "EOS_UNAVAILABLE"

static func live_enabled() -> bool:
	# Deliberate review gate, NOT a credential-driven automatic activation switch.
	return false
