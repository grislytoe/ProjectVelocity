extends SceneTree
## Dependency-free assertions; explicit exit codes survive release assert stripping.

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)


func _run() -> void:
	var version: Dictionary = Engine.get_version_info()
	_check(version.major == 4 and version.minor == 7 and version.patch == 2,
		"Godot 4.7.2 required")
	_check(Engine.physics_ticks_per_second == 60, "Physics must be 60 Hz")
	_check(ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"Compatibility renderer required")
	_check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep",
		"Competitive view must retain its aspect ratio")
	_check(BuildInfo.VERSION == "0.18.0-dev" and BuildInfo.BUILD_NUMBER == 24,
		"M18 runtime identity; project metadata retained per editor-file preservation agreement")
	_check(BuildInfo.NETWORK_PROTOCOL_VERSION == 3,
		"M16 durable race baseline requires protocol 3")
	_check(BuildInfo.is_development() == OS.is_debug_build(), "Build flag mismatch")
	_check(BuildInfo.channel() == "DEV", "Editor tests must run as DEV")
	var config: AppConfig = load("res://core/config/default_app_config.tres") as AppConfig
	_check(config != null and config.log_debug_messages, "Default config failed to load")
	var logger: Node = root.get_node_or_null("AppLogger")
	_check(logger != null, "Logger autoload missing")
	if logger != null:
		_check(logger.format_entry("INFO", "test", "one\ntwo\rthree") ==
			"[INFO][test] one two three", "Logger must sanitize newlines")
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		_check(TranslationServer.translate("BOOTSTRAP_STATUS") != "BOOTSTRAP_STATUS",
			"Missing bootstrap translation: " + locale)
	var scene: PackedScene = load("res://core/bootstrap/main.tscn") as PackedScene
	_check(scene != null, "Main scene failed to load")
	if scene != null:
		var main: Node = scene.instantiate()
		var save_path: String = OS.get_cache_dir().path_join(
			"project_velocity_m0-test-" + PlayerProfileData.new_uuid())
		main.save_store = SaveStore.new(save_path)
		root.add_child(main)
		await process_frame
		DirAccess.remove_absolute(save_path.path_join("save.json"))
		DirAccess.remove_absolute(save_path)
		var label: Label = main.get_node("Center/Content/BuildLabel") as Label
		_check(label.visible and label.text == BuildInfo.label(), "DEV watermark missing")
		main.queue_free()
		await process_frame
	if _failures == 0:
		print("PROJECTVELOCITY_TESTS_OK")
	quit(0 if _failures == 0 else 1)
