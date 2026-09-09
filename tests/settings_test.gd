extends SceneTree
## Isolated schema/transaction/real AudioServer and render-property checks.

var failures: int = 0
var folder: String

class FakeDisplay extends DisplayAdapter:
	var state: Dictionary = {"mode": 0, "borderless": false, "size": Vector2i(1280, 720), "position": Vector2i(20, 20)}
	var fail: bool = false
	var restores: int = 0
	func snapshot() -> Dictionary:
		return state.duplicate(true)
	func apply(video: Dictionary) -> bool:
		state.size = Vector2i(video.resolution[0], video.resolution[1])
		return not fail
	func matches(_video: Dictionary) -> bool:
		return not fail
	func restore(value: Dictionary) -> void:
		state = value.duplicate(true)
		restores += 1

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run() -> void:
	folder = OS.get_cache_dir().path_join("pv-m12-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated open")
	var uuid: String = store.data.profile.uuid
	store.data["foreign"] = {"retained": true}
	store.data.settings.video["future"] = 42
	store.data.settings.audio.mutes["foreign_bus"] = true
	store.data.onboarding_complete = true
	var records := TrialRecords.new(store, TrialMapDefinition.new())
	check(records.complete(600, [200, 400], true).saved, "PB fixture")
	check(store.save(), "Foreign fields fixture")
	var old: Dictionary = store.data.duplicate(true)
	old.save_version = 4
	old.settings.video.erase("post_intensity")
	old.settings.video.erase("speed_intensity")
	old.settings.audio.erase("mutes")
	for key: String in ["text_size", "colorblind", "disable_strong_flashes"]:
		old.settings.accessibility.erase(key)
	var migrated: Dictionary = SaveSchema.decode(old)
	check(migrated.status == "valid" and migrated.data.profile.uuid == uuid,
		"Sequential v4 migration preserves identity")
	check(migrated.data.foreign.retained and migrated.data.settings.video.future == 42,
		"Migration preserves foreign fields")
	var layer := InputLayer.new()
	layer.watch_hardware = false
	root.add_child(layer)
	var preferences := InputPreferences.new()
	preferences.store = store
	preferences.layer = layer
	root.add_child(preferences)
	var runtime := SettingsRuntime.new()
	root.add_child(runtime)
	runtime.apply(store.data.settings)
	var session := SettingsSession.new()
	session.store = store
	session.preferences = preferences
	session.runtime = runtime
	var display := FakeDisplay.new()
	session.adapter = display
	root.add_child(session)
	session.begin()
	for cap: int in SettingsValues.FPS:
		session.draft.video.fps_limit = cap
		check(session.apply(), "Apply cap")
		check(Engine.max_fps == cap and Engine.physics_ticks_per_second == 60, "Render cap only")
		var reload := SaveStore.new(folder)
		check(reload.open() and reload.data.settings.video.fps_limit == cap, "Cap reload")
	for preset: String in SettingsValues.PRESETS:
		session.draft.video.effects_quality = preset
		check(session.apply(), "Preset apply")
		check(root.canvas_item_default_texture_filter == SettingsValues.PRESETS[preset].filter, "Real viewport texture filter")
	for bus: String in SettingsValues.BUSES:
		for volume: float in [0.0, 0.25, 1.0]:
			session.draft.audio[bus.to_lower()] = volume
			check(session.apply(), "Audio apply")
			var index: int = AudioServer.get_bus_index(bus)
			check(AudioServer.is_bus_mute(index) == (volume == 0), "Real zero-volume mute")
			if volume > 0:
				check(is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(index)), volume), "Real bus gain")
		for muted: bool in [true, false]:
			session.draft.audio.mutes[bus.to_lower()] = muted
			check(session.apply() and AudioServer.is_bus_mute(AudioServer.get_bus_index(bus)) == muted, "Explicit bus mute")
	for correction: String in SettingsValues.CORRECTIONS:
		session.draft.accessibility.colorblind = correction
		check(session.apply(), "Color correction apply")
		check(runtime.filter_material.get_shader_parameter("correction") == SettingsValues.CORRECTIONS.find(correction), "Real shader correction")
	for scale: float in [0.5, 1.0, 1.5, 2.0]:
		session.draft.accessibility.ui_scale = scale
		check(session.apply(), "Scale apply")
		check(root.content_scale_size == Vector2i(1920, 1080) and root.content_scale_aspect == Window.CONTENT_SCALE_ASPECT_KEEP,
			"Scale cannot widen competitive framing")
	for field: String in ["high_contrast", "disable_strong_flashes"]:
		for value: bool in [true, false]:
			session.draft.accessibility[field] = value
			check(session.apply() and SettingsRuntime.access(field, null) == value, "Accessibility toggle applies")
	for field: String in ["flash_intensity", "screen_shake", "hud_opacity", "text_size"]:
		var values: Array = [0.0, 0.25, 0.5, 1.0]
		if field == "hud_opacity":
			values = [0.5, 0.75, 1.0]
		elif field == "text_size":
			values = [0.75, 1.0, 1.5]
		for value: float in values:
			session.draft.accessibility[field] = value
			check(session.apply() and is_equal_approx(SettingsRuntime.access(field, -1), value), "Accessibility numeric applies")
	for field: String in ["post_intensity", "speed_intensity"]:
		for value: float in [0.0, 0.5, 1.0]:
			session.draft.video[field] = value
			check(session.apply() and SettingsRuntime.video(field, -1) == value, "Visual intensity applies")
	var reopened := SaveStore.new(folder)
	check(reopened.open() and reopened.data.settings == JSON.parse_string(JSON.stringify(store.data)).settings, "All categories reload together")
	var prior: Dictionary = display.snapshot()
	session.draft.video.resolution = [1280, 720]
	check(session.apply() and session.previewing, "Preview starts")
	check(store.data.settings.video.resolution == [1920, 1080], "Preview not saved")
	session.revert()
	check(display.state == prior and not session.previewing, "Revert restores actual working window")
	session.draft.video.resolution = [1280, 720]
	session.apply()
	session._process(16)
	check(not session.previewing and display.state == prior, "15-second timeout")
	session.draft.video.resolution = [1280, 720]
	session.apply()
	session._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not session.previewing and display.state == prior, "Focus interruption")
	display.fail = true
	session.draft.video.resolution = [1280, 720]
	check(not session.apply() and display.state == prior, "Partial native apply failure rollback")
	display.fail = false
	session.draft.video.resolution = [1280, 720]
	check(session.apply() and session.keep(), "Keep saves")
	check(store.data.settings.video.resolution == [1280, 720], "Confirmed resolution saved")
	session.draft.video.resolution = [1600, 900]
	session.apply()
	store.read_only = true
	check(not session.keep() and not session.previewing, "Write failure rolls display back")
	check(session.error_key == "TT_SAVE_FAILED", "Failure not success")
	store.read_only = false
	session.cancel()
	session.begin()
	check(layer.rebind("keyboard", "jump", [InputBindings.key(KEY_J)]).ok, "Draft binding")
	preferences.flush()
	check(store.data.settings.controls.input.profiles.keyboard.is_empty(), "Debounce excludes draft bindings")
	session.cancel()
	check(layer.bindings("keyboard", "jump") == InputBindings.defaults("keyboard").jump, "Cancel restores input")
	session.begin()
	check(layer.rebind("keyboard", "jump", [InputBindings.key(KEY_J)]).ok and session.apply(), "Binding apply")
	check(store.data.settings.controls.input.profiles.gamepad.is_empty(), "Independent gamepad profile")
	check(not layer.rebind("keyboard", "dash", [InputBindings.key(KEY_J)]).ok, "Conflict rejected")
	for group: String in ["video", "audio", "accessibility", "controls"]:
		session.defaults(group)
	check(session.apply() and session.keep(), "Defaults display confirmation")
	check(store.data.profile.uuid == uuid and store.data.foreign.retained and store.data.settings.video.future == 42, "Settings preserve identity and foreign fields")
	check(store.data.onboarding_complete and records.best().total == 600 and records.best().splits == [200, 400], "Onboarding and real PB survive defaults")
	check(store.data.settings.audio.mutes.foreign_bus, "Nested foreign fields survive defaults")
	var corrupt: Dictionary = store.data.duplicate(true)
	corrupt.settings.video.fps_limit = 59
	check(not SaveSchema.validate(corrupt), "Invalid cap rejected")
	corrupt = store.data.duplicate(true)
	corrupt.settings.audio.mutes = {"master": 1}
	check(not SaveSchema.validate(corrupt), "Corrupt mute rejected")
	for category: String in ["video", "audio", "accessibility"]:
		for field: String in SettingsValues.defaults()[category]:
			corrupt = store.data.duplicate(true)
			corrupt.settings[category][field] = null
			check(not SaveSchema.validate(corrupt), "Every required setting rejects null: " + field)
	session.cancel()
	session.begin()
	session.draft.video.resolution = [1280, 720]
	session.apply()
	var restore_count: int = display.restores
	session.free()
	check(display.restores == restore_count + 1, "Teardown restores preview without callbacks")
	check(runtime.world.viewport.size == WorldPresentation.render_size(store.data.settings.video.resolution),
		"Teardown restores confirmed render pixels")
	preferences.free()
	layer.free()
	runtime.free()
	for filename: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(filename))
	DirAccess.remove_absolute(folder)
	if failures == 0:
		print("PROJECTVELOCITY_M12_OK")
	quit(0 if failures == 0 else 1)
