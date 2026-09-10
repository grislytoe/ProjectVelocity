extends SceneTree
## Isolated disk and real scene/trigger/UI lifecycle regression.

var checks: int = 0
var failures: int = 0
var observer: Observer
var trial: SoloTrial
var folder: String
var replay: String = ""

class DeniedStore extends SaveStore:
	func _replace(_staged: String, _target: String) -> bool:
		return false

class Observer extends Node:
	signal stepped
	func _physics_process(_delta: float) -> void:
		stepped.emit()

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func ticks(count: int) -> void:
	for index: int in count:
		await observer.stepped

func run() -> void:
	folder = OS.get_cache_dir().path_join("pv-m10-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated store creation")
	var legacy: Dictionary = store.data.duplicate(true)
	legacy.save_version = 2
	legacy.erase("trial_records")
	legacy.time_trial_records = {"old": {"best_time_ms": 100}}
	var migrated: Dictionary = SaveSchema.decode(legacy)
	check(migrated.status == "valid" and migrated.data.save_version == SaveSchema.CURRENT_VERSION, "v2 migration")
	check(migrated.data.profile.uuid == legacy.profile.uuid and
		migrated.data.time_trial_records == legacy.time_trial_records, "Legacy identity/data preserved")
	var legacy_file := FileAccess.open(folder.path_join("save.json"), FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(legacy))
	legacy_file.close()
	check(store.open() and store.data.save_version == SaveSchema.CURRENT_VERSION and store.data.profile.uuid == legacy.profile.uuid,
		"v2 disk migration re-saves current schema without changing identity")
	var records := TrialRecords.new(store, TrialMapDefinition.new())
	check(records.complete(600, [200, 400], true).new_pb, "First PB")
	check(not records.complete(600, [100, 450], true).new_pb, "Equal time preserves PB splits")
	check(records.best().splits == [200, 400], "Equal PB unchanged")
	check(not records.complete(700, [100, 500], true).new_pb, "Worse run")
	check(records.best().segments == [100, 200, 150], "Individual best segments include finish")
	check(not records.complete(100, [20, 40], false).saved, "Invalid never saves")
	check(not records.complete(100, [40, 20], true).saved, "Non-monotonic splits rejected")
	check(records.complete(500, [160, 330], true).new_pb, "Improved PB")
	var loaded := SaveStore.new(folder)
	check(loaded.open() and TrialRecords.new(loaded, TrialMapDefinition.new()).best().total == 500,
		"PB roundtrip")
	store.read_only = true
	check(not records.complete(400, [100, 300], true).saved and records.best().total == 500,
		"Failed save preserves memory and disk PB")
	store.read_only = false
	var denied := DeniedStore.new(folder)
	denied.data = store.data.duplicate(true)
	var denied_records := TrialRecords.new(denied, TrialMapDefinition.new())
	check(not denied_records.complete(400, [100, 300], true).saved
		and denied_records.best().total == 500, "Actual replacement failure restores session PB")
	check(loaded.open() and TrialRecords.new(loaded, TrialMapDefinition.new()).best().total == 500,
		"Replacement failure preserves disk PB")
	var bad: Dictionary = store.data.duplicate(true)
	bad.trial_records[records.key()].splits = [999, 12]
	check(not SaveSchema.validate(bad), "Corrupt record rejected")
	var other := TrialMapDefinition.new()
	other.map_version += 1
	check(TrialRecords.new(store, other).best().is_empty(), "Map version isolates PB")
	var changed_records := TrialRecords.new(store, TrialMapDefinition.new())
	changed_records.checksum = "changed".sha256_text()
	check(changed_records.best().is_empty(), "Content hash isolates PB")
	var previous_uuid: String = store.data.profile.uuid
	store.data.profile.uuid = PlayerProfileData.new_uuid()
	check(records.best().is_empty(), "Player UUID isolates PB")
	store.data.profile.uuid = previous_uuid
	check(TrialRecord.format_time(1) == "00:00.017" and TrialRecord.format_time(3) == "00:00.050"
		and TrialRecord.format_time(3600) == "01:00.000", "Unified boundary rounding")
	var layer := InputLayer.new()
	layer.watch_hardware = false
	root.add_child(layer)
	observer = Observer.new()
	observer.process_physics_priority = 200
	observer.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(observer)
	trial = SoloTrial.new()
	trial.layer = layer
	trial.records = records
	root.add_child(trial)
	Input.action_press(layer.action_name("move_right"))
	await ticks(179)
	check(trial.phase == SoloTrial.Phase.HINT and trial.course.player.position.x == 100,
		"Hint blocks real movement for up to 3 seconds")
	await ticks(1)
	check(trial.phase == SoloTrial.Phase.COUNTDOWN, "Hint auto dismissal")
	await ticks(179)
	check(trial.elapsed == 0 and trial.course.player.start_blocked, "Countdown clock/control locked")
	await ticks(1)
	check(trial.phase == SoloTrial.Phase.RUN and trial.elapsed == 0, "Exact GO zero tick")
	await ticks(60)
	check(trial.elapsed == 60, "One second at every render rate")
	check(not trial.course.lifecycle.finish(), "Mandatory finish refusal")
	check(not trial.course.lifecycle.checkpoint(&"b", Vector2(2750, 566)), "Out of order rejected")
	var prior: int = trial.elapsed
	check(trial.course.player.die(), "Ordinary death")
	await ticks(28)
	check(trial.elapsed == prior + 28 and trial.deaths == 1 and trial.valid,
		"Death/respawn continues valid clock")
	paused = true
	prior = trial.elapsed
	await ticks(12)
	check(trial.elapsed == prior and trial.valid, "Pause freezes simulation without invalidation")
	paused = false
	await ticks(45)
	# Move into real trigger volumes; fixture placement isn't an exposed developer command.
	trial.course.player.respawn_at(Vector2(1400, 566), true)
	await ticks(3)
	check(trial.splits.size() == 1 and trial.course.lifecycle.progress.reached == [&"a"],
		"Real checkpoint collision records one timestamp")
	trial.course.player.respawn_at(Vector2(2800, 566), true)
	await ticks(3)
	check(trial.splits.size() == 2, "Real second trigger")
	trial.course.player.respawn_at(Vector2(4020, 566), true)
	await ticks(3)
	check(trial.phase == SoloTrial.Phase.RESULT and trial.result.saved, "Real Finish persists immediately")
	replay = str(trial.elapsed) + ":" + str(trial.splits) + ":" + str(trial.deaths)
	prior = trial.elapsed
	await ticks(8)
	check(trial.elapsed == prior and trial.course.world.active_count() == 0, "Finish clock/pool cleanup")
	trial.request_retry()
	await ticks(1)
	check(trial.phase == SoloTrial.Phase.COUNTDOWN and trial.splits.is_empty() and trial.deaths == 0,
		"Retry no hint and all attempt counters reset")
	trial.course.player.respawn_at(Vector2(1400, 566))
	check(not trial.valid, "Developer teleport invalidates")
	trial.request_retry()
	await ticks(1)
	await ticks(180)
	trial.course.player.die(true)
	check(not trial.valid, "Force death invalidates")
	Input.action_press(layer.action_name("restart"))
	await ticks(29)
	check(not trial.valid, "Restart hold threshold not early")
	await ticks(1)
	check(trial.phase == SoloTrial.Phase.COUNTDOWN and trial.valid, "Quick Restart in respawn")
	var new_course: int = trial.course.get_instance_id()
	await ticks(70)
	check(trial.course.get_instance_id() == new_course, "Held restart fires once until release")
	Input.action_release(layer.action_name("restart"))
	await ticks(1)
	Input.action_press(layer.action_name("restart"))
	await ticks(30)
	check(trial.course.get_instance_id() != new_course, "Fresh hold allows next restart")
	Input.action_release(layer.action_name("restart"))
	var count: int = get_node_count()
	for cycle: int in 12:
		trial.request_retry()
		await ticks(2)
		check(get_node_count() == count and trial.course.player.died.get_connections().size() == 3,
			"Repeat rebuild has stable nodes and signal ownership")
	trial.free()
	var ui := TrialUI.new()
	ui.store = store
	ui.input_layer = layer
	root.add_child(ui)
	check(ui.screen == "menu", "Real menu")
	ui.show_maps()
	check(ui.screen == "maps", "Real map select")
	ui.start_map()
	check(ui.trial.phase == SoloTrial.Phase.HINT, "Menu entry restores hint")
	ui.trial.dismiss_hint()
	ui.toggle_pause()
	check(paused, "Pause GUI")
	ui.toggle_pause()
	ui.show_menu()
	check(not paused and not is_instance_valid(ui.trial), "Menu frees active course")
	ui.show_maps()
	ui.start_map()
	check(ui.trial.phase == SoloTrial.Phase.HINT, "Repeated menu entry has no freed HUD references")
	ui.trial.dismiss_hint()
	await ticks(180)
	ui.trial.invalidate()
	ui.trial.course.player.respawn_at(Vector2(1400, 566), true)
	await ticks(3)
	ui.trial.course.player.respawn_at(Vector2(2800, 566), true)
	await ticks(3)
	ui.trial.course.player.respawn_at(Vector2(4020, 566), true)
	await ticks(3)
	check(ui.trial.phase == SoloTrial.Phase.RESULT and not ui.trial.result.saved,
		"Real invalid Finish never persists")
	ui.refresh()
	check(ui.column.get_child(2).text == ui.tr("TT_INVALID"), "GUI shows invalid result")
	ui.show_menu()
	ui.free()
	layer.free()
	observer.queue_free()
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
	if failures == 0:
		print("M10_REPLAY_HASH=" + replay.sha256_text())
		print("PROJECTVELOCITY_M10_OK checks=%d" % checks)
	quit(0 if failures == 0 else 1)
