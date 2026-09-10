extends SceneTree
## Structural mutations, real assembly, safe rejection and schema-5 record compatibility.

var failures: int = 0
var checks: int = 0
var fixture_dir: String = "res://builds/m13-fixtures"

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, label_value: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label_value)

func rejects(map: MapDefinition, code: String) -> void:
	var report: MapDiagnostics = MapValidator.inspect(map, false)
	check(report.errors.any(func(error: Dictionary) -> bool: return error.code == code),
		"Expected %s: %s" % [code, report.describe()])

func scene_variant(map: MapDefinition, index: int, mutate: Callable, filename: String) -> void:
	var definition: MapSectionDefinition = map.sections[index].section
	var root_node: Node = load(definition.scene_path).instantiate()
	mutate.call(root_node)
	var packed := PackedScene.new()
	check(packed.pack(root_node) == OK, "Pack isolated scene mutation")
	root_node.free()
	definition.scene_path = fixture_dir.path_join(filename + ".tscn")
	check(ResourceSaver.save(packed, definition.scene_path) == OK, "Save isolated scene mutation")

func single() -> MapDefinition:
	var map: MapDefinition = MapCatalog.training()
	map.sections.resize(1)
	map.sections[0].next_id = &""
	map.checkpoints.clear()
	map.finish.section_id = &"first"
	map.finish.anchor = ^"Checkpoint"
	map.declared_checksum = map.checksum()
	return map

func connection_fixture(enabled: bool) -> String:
	var child := Node2D.new()
	child.name = "Child"
	var target := Node2D.new()
	target.name = "Target"
	child.add_child(target)
	target.owner = child
	child.ready.connect(target.set_physics_process.bind(enabled), CONNECT_PERSIST)
	var packed := PackedScene.new()
	check(packed.pack(child) == OK, "Pack persistent nested signal fixture")
	child.free()
	var child_path: String = fixture_dir.path_join("child-%s.tscn" % enabled)
	check(ResourceSaver.save(packed, child_path) == OK, "Save nested signal fixture")
	var source: String = FileAccess.get_file_as_string("res://map_data/sections/training_1.tscn")
	source = source.replace('[sub_resource type="RectangleShape2D"',
		'[ext_resource type="PackedScene" path="%s" id="nested"]\n[sub_resource type="RectangleShape2D"' % child_path)
	source += '\n[node name="Child" parent="." instance=ExtResource("nested")]\n'
	var path: String = fixture_dir.path_join("connections-%s.tscn" % enabled)
	var writer := FileAccess.open(path, FileAccess.WRITE)
	writer.store_string(source)
	writer.close()
	return path

func run() -> void:
	DirAccess.make_dir_recursive_absolute(fixture_dir)
	var map: MapDefinition = MapCatalog.training()
	var hash_value: String = map.checksum()
	check(MapValidator.inspect(map).valid(), "Official multisection map validates")
	check(map.compatible_with(MapCatalog.training()), "Compatible local identity")
	var incompatible: MapDefinition = MapCatalog.training()
	incompatible.map_version += 1
	check(not map.compatible_with(incompatible), "Different version rejected before comparison")
	incompatible = MapCatalog.training()
	incompatible.declared_checksum = "bad"
	check(not map.compatible_with(incompatible), "Tampered declared identity is incompatible")
	check(MapValidator.inspect(single()).valid(), "Valid single section without checkpoints")
	check(MapCatalog.validate_catalog(MapCatalog.official()).valid(), "Production catalog")
	check(not MapCatalog.validate_catalog([map, map]).valid(), "Duplicate catalog ID rejected")
	rejects(null, "definition")
	rejects(MapDefinition.new(), "identity")
	map = MapCatalog.training()
	map.sections.clear()
	rejects(map, "sections")
	map = MapCatalog.training()
	map.sections[0] = null
	rejects(map, "section")
	map = MapCatalog.training()
	map.sections[0].section = null
	rejects(map, "section")
	map = MapCatalog.training()
	map.sections[1].instance_id = map.sections[0].instance_id
	rejects(map, "id")
	map = MapCatalog.training()
	map.sections[1].section.section_id = map.sections[0].section.section_id
	rejects(map, "id")
	map = MapCatalog.training()
	map.sections[0].next_id = &"first"
	rejects(map, "link")
	map = MapCatalog.training()
	map.sections[2].next_id = &"missing"
	rejects(map, "link")
	map = MapCatalog.training()
	map.sections[1].transform.origin.x += 20
	rejects(map, "seam")
	map = MapCatalog.training()
	map.sections[1].transform.origin.x -= 20
	rejects(map, "overlap")
	for pose: Transform2D in [Transform2D(0.2, Vector2.ZERO),
		Transform2D(0, Vector2(1, 2), 0, Vector2.ZERO), Transform2D(0, Vector2(1, 0)),
		Transform2D(Vector2(INF, 0), Vector2.DOWN, Vector2.ZERO)]:
		map = MapCatalog.training()
		map.sections[0].transform = pose
		rejects(map, "transform")
	map = MapCatalog.training()
	map.grid_pixels = Vector2(NAN, 20)
	rejects(map, "grid")
	map = MapCatalog.training()
	map.sections[0].section.entrance = ^"Missing"
	rejects(map, "anchor")
	map = MapCatalog.training()
	map.sections[0].section.scene_path = "res://missing-map.tscn"
	rejects(map, "dependency")
	map = MapCatalog.training()
	var missing_path: String = fixture_dir.path_join("missing-dependency.tscn")
	var missing_writer := FileAccess.open(missing_path, FileAccess.WRITE)
	missing_writer.store_string(FileAccess.get_file_as_string(map.sections[0].section.scene_path).replace(
		"res://gameplay/hazards/spikes.tscn", "res://missing-module.tscn"))
	missing_writer.close()
	map.sections[0].section.scene_path = missing_path
	rejects(map, "dependency")
	check(map.checksum().is_empty(), "Missing transitive scene dependency cannot produce a valid checksum")
	map = MapCatalog.training()
	map.scene_path = "res://gameplay/player/default_movement.tres"
	rejects(map, "scene")
	map = MapCatalog.training()
	var host: Node2D = load(map.scene_path).instantiate()
	host.position = Vector2(1000, 0)
	var host_scene := PackedScene.new()
	check(host_scene.pack(host) == OK, "Pack displaced host fixture")
	host.free()
	map.scene_path = fixture_dir.path_join("displaced-host.tscn")
	check(ResourceSaver.save(host_scene, map.scene_path) == OK, "Save displaced host fixture")
	rejects(map, "transform")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void: node.get_node("Entrance").top_level = true, "top-level")
	rejects(map, "transform")
	map = MapCatalog.training()
	map.sections[0].section.major_geometry = [^"Missing"]
	rejects(map, "geometry")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void: node.get_node("Exit").position.x -= 20, "seam")
	rejects(map, "seam_support")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void: node.get_node("Floor").position.x += 1, "grid")
	rejects(map, "grid")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void: node.get_node("Entrance").rotation = PI, "rotated")
	rejects(map, "anchor")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void: node.get_node("Spikes").config = null, "config")
	rejects(map, "config")
	map = MapCatalog.training()
	map.start = null
	rejects(map, "point")
	map = MapCatalog.training()
	map.finish.section_id = &"unknown"
	rejects(map, "reference")
	map = MapCatalog.training()
	map.checkpoints[1].point_id = map.checkpoints[0].point_id
	rejects(map, "id")
	map = MapCatalog.training()
	map.checkpoints.reverse()
	rejects(map, "order")
	map = MapCatalog.training()
	map.checkpoints[0].respawn_anchor = ^"../Start"
	rejects(map, "anchor")
	map = MapCatalog.training()
	map.finish.trigger_size.x = 0
	rejects(map, "point")
	map = MapCatalog.training()
	map.par_time_ticks = -1
	rejects(map, "metadata")
	map = MapCatalog.training()
	map.death_bounds.size.x = 0
	rejects(map, "bounds")
	map = MapCatalog.training()
	map.declared_checksum = "0".repeat(64)
	check(MapValidator.inspect(map).message_key() == "MAP_CHECKSUM_ERROR", "Tampered checksum refused")
	map = MapCatalog.training()
	map.resource_name = "Editor label"
	map.description_key = "Different localized description"
	map.expected_duration_seconds += 10
	map.set_meta("_editor_notes", "Ignore this")
	check(map.checksum() == hash_value, "Presentation and editor-only details do not alter identity")
	for locale: String in ["ru", "en", "de"]:
		TranslationServer.set_locale(locale)
		check(map.checksum() == hash_value, "Checksum is locale-independent")
	var report := MapDiagnostics.new()
	check(MapChecksum.encode({"z": 1, "a": 2}, report) ==
		MapChecksum.encode({"a": 2, "z": 1}, report), "Dictionary insertion order ignored")
	map = MapCatalog.training()
	map.checkpoints[0].mandatory = false
	check(map.checksum() != hash_value, "Mandatory metadata affects checksum")
	map = MapCatalog.training()
	scene_variant(map, 0, func(_node: Node) -> void: pass, "unchanged")
	check(map.checksum() == hash_value, "Scene reserialization keeps semantic identity")
	var rewritten: String = FileAccess.get_file_as_string(map.sections[0].section.scene_path)
	rewritten = rewritten.replace('id="floor"', 'id="editor_generated_id"')
	rewritten = rewritten.replace('SubResource("floor")', 'SubResource("editor_generated_id")')
	# Property order, CRLF and comments do not appear in SceneState canonicalization.
	rewritten = rewritten.replace("[node name=\"Section\" type=\"Node2D\"]",
		"[node name=\"Section\" type=\"Node2D\"]\neditor_description = \"Editor note\"")
	var rewritten_path: String = fixture_dir.path_join("rewritten.tscn")
	var writer := FileAccess.open(rewritten_path, FileAccess.WRITE)
	writer.store_string(rewritten.replace("\n", "\r\n"))
	writer.close()
	map.sections[0].section.scene_path = rewritten_path
	check(map.checksum() == hash_value, "Editor metadata and line endings do not alter scene hash")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void: node.get_node("Spikes").position.x += 1, "hazard")
	check(map.checksum() != hash_value, "Fine hazard placement affects checksum")
	check(not MapValidator.inspect(map).valid(), "Changed scene rejected with old checksum")
	map = MapCatalog.training()
	scene_variant(map, 0, func(node: Node) -> void:
		node.get_node("Spikes").config = node.get_node("Spikes").config.duplicate()
		node.get_node("Spikes").config.size.x += 20, "tuning")
	check(map.checksum() != hash_value, "Dependent resource tuning affects checksum")
	var signal_hashes: Array[String] = []
	for enabled: bool in [false, true]:
		map = MapCatalog.training()
		map.sections[0].section.scene_path = connection_fixture(enabled)
		check(MapValidator.inspect(map, false).valid(), "Nested persistent connection is valid content")
		signal_hashes.append(map.checksum())
	check(not signal_hashes[0].is_empty() and signal_hashes[0] != signal_hashes[1],
		"Changing only inherited signal bind arguments changes map checksum")
	await runtime_checks()
	await records_checks()
	for file: String in DirAccess.get_files_at(fixture_dir):
		DirAccess.remove_absolute(fixture_dir.path_join(file))
	DirAccess.remove_absolute(fixture_dir)
	if failures == 0:
		print("PROJECTVELOCITY_M13_OK checks=%d hash=%s" % [checks, hash_value])
	quit(0 if failures == 0 else 1)

func runtime_checks() -> void:
	var layer := InputLayer.new()
	layer.watch_hardware = false
	root.add_child(layer)
	var folder: String = OS.get_cache_dir().path_join("pv-m13-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated runtime save")
	var baseline: int = get_node_count()
	var orphans: int = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	for index: int in 8:
		var trial := SoloTrial.new()
		trial.layer = layer
		var map: MapDefinition = single() if index % 2 == 0 else MapCatalog.training()
		trial.records = TrialRecords.new(store, map)
		root.add_child(trial)
		await physics_frame
		await physics_frame
		check(trial.phase == SoloTrial.Phase.HINT and trial.course.assembly.sections.size() == map.sections.size(),
			"Real single/multiple section load and physics-safe anchors")
		if map.sections.size() == 3:
			check(trial.course.assembly.point_position(map.checkpoints[1], true) == Vector2(2750, 566),
				"Translated section-local respawn is correct in map space")
		trial.records.definition.declared_checksum = "bad"
		trial.retry()
		check(trial.phase == SoloTrial.Phase.ERROR and trial.course == null and trial.barrier == null,
			"Failed retry tears down actors, pool, barrier and all sections")
		trial.free()
		await process_frame
		check(get_node_count() == baseline, "Repeated load/failure/unload has stable node ownership")
	check(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)) == orphans,
		"Detached validation and assembly do not leak orphan nodes")
	var unsafe: MapDefinition = single()
	scene_variant(unsafe, 0, func(node: Node) -> void: node.get_node("Start").position.y -= 100, "unsafe")
	unsafe.declared_checksum = unsafe.checksum()
	check(MapValidator.inspect(unsafe).valid(), "Structural acceptance does not pretend to prove respawn safety")
	var trial := SoloTrial.new()
	trial.layer = layer
	trial.records = TrialRecords.new(store, unsafe)
	root.add_child(trial)
	await physics_frame
	await physics_frame
	check(trial.phase == SoloTrial.Phase.ERROR and trial.course == null, "Unsafe Start fails before control")
	trial.free()
	var ui := AppUI.new()
	ui.store = store
	ui.input_layer = layer
	root.add_child(ui)
	ui.selected_definition = MapCatalog.training()
	ui.selected_definition.start = null
	ui.start_map()
	await process_frame
	check(ui.trial.phase == SoloTrial.Phase.ERROR and ui.column.get_child(0).text == ui.tr("MAP_INVALID"),
		"Real AppUI shows localized failure without profile/HUD null access")
	ui.show_menu()
	ui.free()
	layer.free()
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)

func records_checks() -> void:
	var folder: String = OS.get_cache_dir().path_join("pv-m13-record-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated record save")
	var uuid: String = store.data.profile.uuid
	var legacy: MapDefinition = MapCatalog.training()
	legacy.map_version = 1
	var records := TrialRecords.new(store, legacy)
	# Actual M12 checksum kept only as a migration fixture; never used by production hashing.
	records.checksum = ("0832bd598cd2e34e22ca69967a1204871f89393d241386f46db1735606ef2072" +
		":res://gameplay/race/solo_course.tscn:[\"a\",\"b\"]").sha256_text()
	check(records.complete(600, [200, 400], true).saved, "Legacy PB stored in schema 5")
	var old_key: String = records.key()
	records = TrialRecords.new(store, MapCatalog.training())
	check(records.best().is_empty(), "M12 PB is preserved but not compared to M13")
	check(records.complete(550, [180, 350], true).saved, "New identity has independent PB")
	check(store.open() and store.data.trial_records.has(old_key) and store.data.profile.uuid == uuid \
		and store.data.save_version == 5, "Disk roundtrip preserves old PB, UUID and schema")
	var flexible: MapDefinition = MapCatalog.training()
	flexible.strict_order = false
	flexible.checkpoints[0].mandatory = false
	records = TrialRecords.new(store, flexible)
	check(records.complete(300, [100], true, [&"b"]).saved, "Optional checkpoint may be omitted")
	check(records.complete(250, [50, 120], true, [&"b", &"a"]).saved, "Unordered legal route records real activation order")
	check(records.best().ids == ["b", "a"] and records.best().segments == [50, 70, 130],
		"Different route does not mix segment minima")
	check(not records.complete(100, [], true, []).saved, "Missing mandatory checkpoint cannot write PB")
	check(not records.complete(100, [], true, false).saved, "Malformed reached metadata fails safely")
	for file: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(file))
	DirAccess.remove_absolute(folder)
