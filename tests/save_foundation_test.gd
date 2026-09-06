extends SceneTree
## All disk fixtures live under a unique OS cache directory, never user://saves.

var _failures: int = 0
var _checks: int = 0
var _root: String
var _counter: int = 0


func _initialize() -> void:
	_root = OS.get_cache_dir().path_join("project_velocity_m1-test-" + PlayerProfileData.new_uuid())
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _store() -> SaveStore:
	_counter += 1
	return SaveStore.new(_root.path_join(str(_counter)))


func _write(store: SaveStore, name: String, content: String) -> void:
	DirAccess.make_dir_recursive_absolute(store.directory)
	var file := FileAccess.open(store.directory.path_join(name), FileAccess.WRITE)
	_check(file != null, "Fixture write must succeed")
	if file != null:
		file.store_string(content)
		file.close()


func _text(store: SaveStore, name: String) -> String:
	return FileAccess.get_file_as_string(store.directory.path_join(name))


func _run() -> void:
	var initial: Dictionary = SaveSchema.defaults()
	_check(PlayerProfileData.validate(initial.profile), "Default profile must validate")
	_check(SaveSchema.validate(initial), "Default schema must validate")
	_check(SaveSchema.decode(JSON.parse_string(JSON.stringify(initial))).status == "valid",
		"Defaults must validate after JSON conversion")
	var store: SaveStore = _store()
	_check(store.open(), "First-run creation: " + store.notification_key)
	_check(store.source == "defaults" and store.notification_key.is_empty(), "First run is normal")
	_check(FileAccess.file_exists(store.directory.path_join("save.json")), "First run persists")
	var uuid: String = store.data.profile.uuid
	_check(PlayerProfileData.matches(uuid,
		"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"), "UUID v4")
	var second: SaveStore = SaveStore.new(store.directory)
	_check(second.open(), "Reload must succeed")
	_check(second.source == "primary" and second.data.profile.uuid == uuid, "UUID stable on reload")
	_check(PlayerProfileData.create().uuid != uuid, "Separate profiles have distinct identities")
	var profile: PlayerProfileData = PlayerProfileData.from_dictionary(second.data.profile)
	_check(profile != null and JSON.parse_string(JSON.stringify(profile.to_dictionary())) ==
		JSON.parse_string(JSON.stringify(second.data.profile)), "Typed profile round trip")
	for nickname: String in ["Amy", "Player_1", "Ёжик", "Гонщик-7", "Іван", "Racer One", "123456789012345"]:
		_check(PlayerProfileData.valid_nickname(nickname), "Valid nickname: " + nickname)
	for nickname: String in ["", "ab", "1234567890123456", "   ", "A😀B", "A\nB", "A\tB",
			"A\rB", "A/B", "A.B", "éab", "中文名", "A\u200bB", "A\u0483B"]:
		_check(not PlayerProfileData.valid_nickname(nickname), "Invalid nickname rejected")
	_check(PlayerProfileData.valid_nickname("Same") and PlayerProfileData.valid_nickname("Same"),
		"Duplicate display names are allowed")

	store.data.profile.nickname = "Гонщик_7"
	store.data.profile.language = "ru"
	store.data.profile.body_color = "ff2244ff"
	store.data.profile.last_input_device = "controller"
	store.data.profile.cosmetic_slots.hat = "future_hat"
	store.data.settings.audio.music = 0.4
	store.data.settings.controls.bindings = {"future_jump": ["keyboard:space"]}
	store.data.time_trial_records = {"map_example": {"best_time_ms": 12345}}
	store.data.checkpoint_splits = {
		"map_example": {"pb_run_ms": [1000, 4000], "best_segment_ms": [900, 2800]}}
	store.data.last_lobby_settings = {"round_count": 3, "map_id": "map_example"}
	_check(store.save(), "Save full foundation data")
	var loaded: SaveStore = SaveStore.new(store.directory)
	_check(loaded.open(), "Full JSON reload")
	_check(loaded.data.profile.uuid == uuid and loaded.data.profile.language == "ru",
		"UUID and language persist")
	var expected: Dictionary = store.data.duplicate(true)
	expected.profile.last_launch_at = loaded.data.profile.last_launch_at
	_check(JSON.parse_string(JSON.stringify(loaded.data)) ==
		JSON.parse_string(JSON.stringify(expected)), "Full JSON round trip")
	_check(loaded.data.save_version == SaveSchema.CURRENT_VERSION, "Version detected")
	var previous: Dictionary = JSON.parse_string(_text(loaded, "save.backup.json"))
	_check(previous.profile.uuid == uuid, "Backup retains identity")
	loaded.data.profile.nickname = "Newest"
	_check(loaded.save(), "Second explicit save")
	previous = JSON.parse_string(_text(loaded, "save.backup.json"))
	_check(previous.profile.nickname == "Гонщик_7", "Backup contains previous known-good data")
	_write(loaded, "save.json", "{ broken")
	var recovered: SaveStore = SaveStore.new(loaded.directory)
	_check(recovered.open(), "Backup recovery succeeds")
	_check(recovered.source == "backup" and recovered.notification_key == "SAVE_RECOVERED",
		"Recovery is exposed to UI")
	_check(recovered.data.profile.uuid == uuid and recovered.data.profile.nickname == "Гонщик_7",
		"Recovery retains backup identity and values")
	_check(SaveSchema.decode(JSON.parse_string(_text(recovered, "save.json"))).status == "valid",
		"Recovered primary repaired")
	_check(SaveSchema.decode(JSON.parse_string(_text(recovered, "save.backup.json"))).status == "valid",
		"Good backup preserved")
	var missing_primary: SaveStore = _store()
	_write(missing_primary, "save.backup.json", JSON.stringify(initial))
	_check(missing_primary.open() and missing_primary.source == "backup", "Missing primary uses backup")

	var broken: SaveStore = _store()
	_write(broken, "save.json", "{ invalid primary")
	_write(broken, "save.backup.json", "[ invalid backup")
	_check(broken.open(), "Both invalid create persisted defaults")
	_check(broken.source == "defaults" and broken.notification_key == "SAVE_RESET",
		"Default recovery notification")
	_check(SaveSchema.validate(broken.data), "Recovered defaults valid")
	var quarantined: int = 0
	for filename: String in DirAccess.get_files_at(broken.directory):
		if ".corrupt-" in filename:
			quarantined += 1
	_check(quarantined == 2, "Corrupt originals quarantined")

	for invalid: Variant in [null, [], "wrong", 42, {}, {"save_version": "1"},
			{"save_version": 1.5}, {"save_version": -1}, {"save_version": true}]:
		_check(SaveSchema.decode(invalid).status == "invalid", "Invalid root/version rejected")
	for key: String in initial:
		var missing: Dictionary = initial.duplicate(true)
		missing.erase(key)
		_check(SaveSchema.decode(missing).status == "invalid", "Missing field rejected: " + key)
	for key: String in initial.profile:
		var missing: Dictionary = initial.duplicate(true)
		missing.profile.erase(key)
		_check(SaveSchema.decode(missing).status == "invalid", "Missing profile field: " + key)
	for invalid: Variant in ["no", null, true, 0, [], {}]:
		var malformed: Dictionary = initial.duplicate(true)
		malformed.profile.nickname = invalid
		_check(SaveSchema.decode(malformed).status == "invalid", "Wrong nickname type/value")
	var invalid_settings: Dictionary = initial.duplicate(true)
	invalid_settings.settings.audio.master = 2.0
	_check(SaveSchema.decode(invalid_settings).status == "invalid", "Invalid volume")
	invalid_settings = initial.duplicate(true)
	invalid_settings.settings.video.resolution = ["1920", 1080]
	_check(SaveSchema.decode(invalid_settings).status == "invalid", "Invalid resolution")
	invalid_settings = initial.duplicate(true)
	invalid_settings.profile.uuid = "nickname-as-identity"
	_check(SaveSchema.decode(invalid_settings).status == "invalid", "Invalid UUID")
	var valid_bytes: String = _text(recovered, "save.json")
	recovered.data.profile.nickname = "😃"
	_check(not recovered.save() and recovered.notification_key == "SAVE_INVALID", "Reject invalid write")
	_check(_text(recovered, "save.json") == valid_bytes, "Rejected write preserves good primary")

	var legacy: Dictionary = initial.duplicate(true)
	legacy.save_version = 0
	legacy.erase("last_lobby_settings")
	var migrated: Dictionary = SaveSchema.decode(legacy)
	_check(migrated.status == "valid" and migrated.migrated, "Version 0 migrates sequentially")
	_check(legacy.save_version == 0 and not legacy.has("last_lobby_settings"), "Migration is pure")
	if migrated.status == "valid":
		_check(migrated.data.profile.uuid == initial.profile.uuid, "Migration preserves UUID")
		_check(migrated.data.last_lobby_settings.round_count == 1, "Migration adds defaults")
	var migration_store: SaveStore = _store()
	_write(migration_store, "save.json", JSON.stringify(legacy))
	_check(migration_store.open(), "Migration loads from disk")
	_check(JSON.parse_string(_text(migration_store, "save.json")).save_version == 1,
		"Migrated schema persisted")

	var future: Dictionary = initial.duplicate(true)
	future.save_version = SaveSchema.CURRENT_VERSION + 1
	_check(SaveSchema.decode(future).status == "unsupported", "Future schema detected")
	var future_store: SaveStore = _store()
	_write(future_store, "save.json", JSON.stringify(future))
	_write(future_store, "save.backup.json", JSON.stringify(initial))
	var future_bytes: String = _text(future_store, "save.json")
	_check(future_store.open() and future_store.read_only, "Future version opens read-only")
	_check(future_store.source == "backup" and future_store.notification_key == "SAVE_UNSUPPORTED",
		"Future version can load supported backup without overwriting")
	_check(not future_store.save() and _text(future_store, "save.json") == future_bytes,
		"Future save preserved byte-for-byte")
	var unsupported_only: SaveStore = _store()
	_write(unsupported_only, "save.json", JSON.stringify(future))
	_check(unsupported_only.open() and unsupported_only.read_only and
		SaveSchema.validate(unsupported_only.data), "Future save without backup uses session defaults")
	_check(_text(unsupported_only, "save.json") == future_bytes, "No downgrade without backup")

	for invalid: Variant in [null, [], {}, {"save_version": "1"}]:
		var bad_primary: SaveStore = _store()
		_write(bad_primary, "save.json", JSON.stringify(invalid))
		_check(bad_primary.open() and bad_primary.notification_key == "SAVE_RESET",
			"Invalid root/structure recovers safely on disk")
	var oversized: SaveStore = _store()
	_write(oversized, "save.json", "x".repeat(SaveStore.MAX_SAVE_BYTES + 1))
	_write(oversized, "save.backup.json", JSON.stringify(initial))
	_check(oversized.open() and oversized.source == "backup", "Oversized primary uses backup")
	var primary_wins: SaveStore = _store()
	_write(primary_wins, "save.json", JSON.stringify(initial))
	_write(primary_wins, "save.backup.json", "broken")
	_check(primary_wins.open() and primary_wins.source == "primary" and
		primary_wins.notification_key.is_empty(), "Valid primary wins over invalid backup")
	_check(SaveSchema.decode(JSON.parse_string(_text(primary_wins, "save.backup.json"))).status ==
		"valid", "Valid primary repairs corrupt backup")
	var malformed_legacy: Dictionary = legacy.duplicate(true)
	malformed_legacy.profile.erase("uuid")
	_check(SaveSchema.decode(malformed_legacy).status == "invalid", "Migration validates result")

	# Simulate a write failure by placing a directory where the staging file must go.
	var failed_store: SaveStore = _store()
	_check(failed_store.open(), "Write-failure fixture")
	var before: String = _text(failed_store, "save.json")
	DirAccess.make_dir_absolute(failed_store.directory.path_join("save.tmp"))
	failed_store.data.profile.nickname = "Changed"
	_check(not failed_store.save() and failed_store.notification_key == "SAVE_IO_ERROR",
		"Staging failure is nonfatal")
	_check(_text(failed_store, "save.json") == before, "I/O failure preserves only good save")
	var failed_backup: SaveStore = _store()
	_check(failed_backup.open(), "Backup-failure fixture")
	before = _text(failed_backup, "save.json")
	DirAccess.make_dir_absolute(failed_backup.directory.path_join("backup.tmp"))
	failed_backup.data.profile.nickname = "Changed"
	_check(not failed_backup.save(), "Backup staging failure aborts replacement")
	_check(_text(failed_backup, "save.json") == before, "Backup failure preserves good primary")
	for locale: String in ["en", "ru"]:
		TranslationServer.set_locale(locale)
		for key: String in ["SAVE_RECOVERED", "SAVE_RESET", "SAVE_UNSUPPORTED", "SAVE_IO_ERROR", "SAVE_INVALID"]:
			_check(TranslationServer.translate(key) != key, "Recovery translation: " + locale + key)
	_cleanup(_root)
	_check(not DirAccess.dir_exists_absolute(_root), "Isolated test files removed")
	if _failures == 0:
		print("PROJECTVELOCITY_M1_TESTS_OK (%d checks)" % _checks)
	quit(0 if _failures == 0 else 1)


func _cleanup(path: String) -> void:
	if not path.begins_with(_root) or not DirAccess.dir_exists_absolute(path):
		return
	for name: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(name))
	for name: String in DirAccess.get_directories_at(path):
		_cleanup(path.path_join(name))
	DirAccess.remove_absolute(path)
