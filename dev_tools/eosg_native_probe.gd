extends SceneTree
## Explicit native-only M18 gate. No autoload, game transport or service login.
## Launcher supplies a checksum-inspected candidate; never print SDK callbacks or identities.

class InitializeOptions extends RefCounted:
	var product_name: String = "ProjectVelocityCompatibilityGate"
	var product_version: String = "0.18.0"

class RTCOptions extends RefCounted:
	var background_mode: Variant = null

class InvalidPlatformOptions extends RefCounted:
	var product_id: String = "invalid"
	var sandbox_id: String = "invalid"
	var deployment_id: String = "invalid"
	var client_id: String = ""
	var client_secret: String = ""
	var encryption_key: String = ""
	var flags: int = 6 # DisableOverlay | DisableSocialOverlay in pinned EOSG 2.3.0.
	var is_server: bool = false
	var tick_budget_in_milliseconds: int = 1
	var task_network_timeout_seconds: Variant = null
	var override_country_code: String = ""
	var override_locale_code: String = ""
	var cache_directory: String = ""
	var rtc_options: RefCounted = RTCOptions.new()

var _sdk: Object
var _initialized: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not OS.get_cmdline_user_args().has("--eosg-native-probe"):
		print("M18_OPT_IN_REQUIRED")
		quit(2)
		return
	var candidate: String = OS.get_environment("PV_EOSG_PROBE_EXTENSION")
	if candidate.is_empty() or not FileAccess.file_exists(candidate):
		print("M18_BLOCKED category=missing_native_library")
		quit(2)
		return
	var result: int = GDExtensionManager.load_extension(candidate)
	print("M18_NATIVE_LOAD result=%d" % result)
	if result != GDExtensionManager.LOAD_STATUS_OK or not Engine.has_singleton("IEOS"):
		print("M18_BLOCKED category=plugin_load_abi_api_or_dependency")
		quit(2)
		return
	_sdk = Engine.get_singleton("IEOS")
	for method: String in ["platform_interface_initialize", "platform_interface_create",
		"platform_interface_release", "platform_interface_shutdown", "tick",
		"auth_interface_login", "connect_interface_login", "lobby_interface_create_lobby",
		"lobby_interface_create_lobby_search", "lobby_interface_join_lobby",
		"lobby_interface_update_lobby", "lobby_interface_leave_lobby",
		"lobby_interface_destroy_lobby", "version_interface_get_version"]:
		if not _sdk.has_method(method):
			print("M18_FAIL category=api_mismatch method=%s" % method)
			quit(1)
			return
	for method: String in ["create_server", "create_client", "set_auto_accept_connection_requests",
		"accept_connection_request", "deny_connection_request", "poll", "put_packet",
		"get_packet", "close", "set_transfer_channel"]:
		if not ClassDB.class_has_method("EOSGMultiplayerPeer", method):
			print("M18_FAIL category=p2p_api_mismatch method=%s" % method)
			quit(1)
			return
	print("M18_API_SURFACE_OK live_services=false")
	print("M18_SDK_VERSION %s" % str(_sdk.call("version_interface_get_version")))
	# EOS global shutdown is terminal for this process. Repeat using separate OS processes.
	for cycle: int in range(1):
		var init_result: int = int(_sdk.call("platform_interface_initialize", InitializeOptions.new()))
		print("M18_INITIALIZE cycle=%d result=%d" % [cycle, init_result])
		if init_result != 0:
			print("M18_FAIL category=sdk_initialization")
			quit(1)
			return
		_initialized = true
		if OS.get_cmdline_user_args().has("--invalid-platform"):
			var created: bool = bool(_sdk.call("platform_interface_create", InvalidPlatformOptions.new()))
			print("M18_INVALID_PLATFORM rejected=%s" % str(not created))
			if created:
				_stop()
				print("M18_FAIL category=unexpected_invalid_platform_acceptance")
				quit(1)
				return
		# Tick without a created platform is only a safe no-op test, not EOS_Platform_Tick proof.
		_sdk.call("tick")
		var shutdown_result: int = _stop()
		print("M18_SHUTDOWN cycle=%d result=%d" % [cycle, shutdown_result])
		if shutdown_result != 0 or _stop() != 0:
			print("M18_FAIL category=sdk_shutdown")
			quit(1)
			return
	print("M18_NATIVE_ONLY_OK cycles=1 platform_created=false")
	print("M18_BLOCKED Auth=credentials Connect=credentials Lobby=two_identities P2P=two_identities")
	quit(0)


func _stop() -> int:
	if not _initialized:
		return 0
	_initialized = false
	_sdk.call("platform_interface_release")
	return int(_sdk.call("platform_interface_shutdown"))


func _finalize() -> void:
	_stop()
