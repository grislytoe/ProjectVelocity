extends Control
## Application services and Solo navigation composition root.

var save_store: SaveStore
var input_layer: InputLayer
var input_preferences: InputPreferences
var settings_runtime: SettingsRuntime
var settings_session: SettingsSession
var _smoke_directory: String = ""

@onready var build_label: Label = %BuildLabel
@onready var prompt_label: Label = %InputPrompt
@onready var _logger: ProjectLogger = get_node("/root/AppLogger")


func _ready() -> void:
	if save_store == null:
		if OS.get_cmdline_user_args().has("--smoke-test"):
			_smoke_directory = OS.get_cache_dir().path_join(
				"project_velocity_smoke-" + PlayerProfileData.new_uuid())
			save_store = SaveStore.new(_smoke_directory)
		else:
			save_store = SaveStore.new()
	save_store.open()
	var resolution: Array = save_store.data.settings.video.resolution
	if int(resolution[0]) < DisplayAdapter.MINIMUM.x or int(resolution[1]) < DisplayAdapter.MINIMUM.y:
		# Upgrade legacy low-resolution settings without resetting the player's save.
		save_store.data.settings.video.resolution = [DisplayAdapter.MINIMUM.x, DisplayAdapter.MINIMUM.y]
		save_store.save()
	TranslationServer.set_locale(save_store.data.profile.language)
	input_layer = InputLayer.new()
	input_layer.configure(save_store.data.settings.controls.input, save_store.data.profile.last_input_device)
	input_preferences = InputPreferences.new()
	input_preferences.store = save_store
	input_preferences.layer = input_layer
	add_child(input_preferences)
	_open_navigation.call_deferred()
	input_layer.prompts_changed.connect(_update_prompts)
	add_child(input_layer)
	settings_runtime = SettingsRuntime.new()
	add_child(settings_runtime)
	settings_runtime.apply(save_store.data.settings)
	settings_session = SettingsSession.new()
	settings_session.store = save_store
	settings_session.runtime = settings_runtime
	settings_session.preferences = input_preferences
	add_child(settings_session)
	if not settings_session.adapter.apply(save_store.data.settings.video):
		save_store.notification_key = "SET_DISPLAY_FAILED"
	_update_prompts()
	build_label.text = BuildInfo.label()
	build_label.visible = BuildInfo.is_development() or OS.has_feature("staging")
	_logger.info("ProjectVelocity %s started" % BuildInfo.label(), "bootstrap")
	if OS.get_cmdline_user_args().has("--smoke-test"):
		_run_smoke_test.call_deferred()


func _open_navigation() -> void:
	$Center.hide()
	var navigation := AppUI.new()
	navigation.store = save_store
	navigation.input_layer = input_layer
	navigation.settings = settings_session
	add_child(navigation)


func _run_smoke_test() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	input_preferences.flush()
	var save_ok: bool = SaveSchema.validate(save_store.data) and (
		save_store.notification_key.is_empty())
	if not _smoke_directory.is_empty():
		for filename: String in ["save.json", "save.backup.json"]:
			if FileAccess.file_exists(_smoke_directory.path_join(filename)):
				DirAccess.remove_absolute(_smoke_directory.path_join(filename))
		DirAccess.remove_absolute(_smoke_directory)
	if not save_ok:
		_logger.error("Save foundation smoke failed", "bootstrap")
		get_tree().quit(1)
		return
	if Engine.physics_ticks_per_second != 60:
		_logger.error("Expected 60 Hz physics", "bootstrap")
		get_tree().quit(1)
		return
	print("PROJECTVELOCITY_BOOT_OK")
	get_tree().quit(0)


func _update_prompts() -> void:
	prompt_label.text = tr("INPUT_PROMPTS") % [
		input_layer.prompt("jump").get("label", ""), input_layer.prompt("dash").get("label", "")]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and input_layer != null and prompt_label != null:
		_update_prompts()
