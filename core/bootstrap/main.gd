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
	if OS.get_cmdline_user_args().has("--local-network"):
		# Export templates disable CLI scene overrides; dispatch before touching player saves.
		if OS.is_debug_build():
			get_tree().change_scene_to_file.call_deferred("res://networking/local_network.tscn")
		else:
			get_tree().quit(1)
		return
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
	print("PV_BUILD_IDENTITY version=%s build=%d channel=%s protocol=%d wire=%d save=%d source_sha=%s" % [
		BuildInfo.VERSION, BuildInfo.BUILD_NUMBER, BuildInfo.channel(),
		BuildInfo.NETWORK_PROTOCOL_VERSION, BuildInfo.NETWORK_WIRE_REVISION,
		SaveSchema.CURRENT_VERSION, BuildInfo.source_sha()])
	# Exercise the same canonical identity and section loading in editor and compiled PCK.
	var training_map := MapCatalog.training()
	var trial := SoloTrial.new()
	trial.layer = input_layer
	trial.records = TrialRecords.new(save_store, training_map)
	settings_runtime.world.viewport.add_child(trial)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var map_ok: bool = trial.phase == SoloTrial.Phase.HINT and is_instance_valid(trial.course)
	print("PV_MAP_BOOT_HASH=" + trial.records.checksum)
	_print_map_checksum_components(training_map)
	trial.free()
	var industrial_map := MapCatalog.industrial()
	trial = SoloTrial.new()
	trial.layer = input_layer
	trial.records = TrialRecords.new(save_store, industrial_map)
	settings_runtime.world.viewport.add_child(trial)
	await get_tree().physics_frame
	await get_tree().physics_frame
	map_ok = map_ok and trial.phase == SoloTrial.Phase.HINT and is_instance_valid(trial.course)
	print("PV_INDUSTRIAL_BOOT_HASH=" + trial.records.checksum)
	_print_map_checksum_components(industrial_map)
	trial.free()
	if not map_ok:
		_logger.error("Map identity/assembly smoke failed", "bootstrap")
		get_tree().quit(1)
		return
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


func _print_map_checksum_components(map: MapDefinition) -> void:
	var components: Array = [["identity", ["PV-MAP-1", MapCodeManifest.DIGEST, map.map_id,
		map.map_version, map.map_type, map.grid_pixels, map.strict_order, map.par_time_ticks,
		map.death_bounds, map.start, map.finish, map.checkpoints, map.camera_bounds,
		map.camera_zones]], ["map_scene", load(map.scene_path)]]
	for path: String in MapCodeManifest.DATA_PATHS:
		components.append(["data:" + path, [path, load(path)]])
	for placement: MapSectionPlacement in map.sections:
		var section: MapSectionDefinition = placement.section
		components.append(["section:" + str(placement.instance_id), [placement.instance_id,
			placement.transform, placement.next_id, section.section_id, section.entrance,
			section.exit, section.major_geometry, load(section.scene_path)]])
	for component: Array in components:
		var report := MapDiagnostics.new()
		var encoded: String = MapChecksum.encode(component[1], report)
		print("PV_MAP_COMPONENT map=%s name=%s sha256=%s valid=%s" % [map.map_id,
			component[0], encoded.sha256_text(), report.valid()])


func _update_prompts() -> void:
	prompt_label.text = tr("INPUT_PROMPTS") % [
		input_layer.prompt("jump").get("label", ""), input_layer.prompt("dash").get("label", "")]


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and input_layer != null and prompt_label != null:
		_update_prompts()
