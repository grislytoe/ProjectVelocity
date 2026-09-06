extends Control
## Placeholder composition root; gameplay and services are added in later milestones.

var save_store: SaveStore
var _smoke_directory: String = ""

@onready var build_label: Label = %BuildLabel
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
	TranslationServer.set_locale(save_store.data.profile.language)
	build_label.text = BuildInfo.label()
	build_label.visible = BuildInfo.is_development() or OS.has_feature("staging")
	_logger.info("ProjectVelocity %s started" % BuildInfo.label(), "bootstrap")
	if OS.get_cmdline_user_args().has("--smoke-test"):
		_run_smoke_test.call_deferred()


func _run_smoke_test() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
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
