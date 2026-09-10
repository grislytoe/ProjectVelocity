extends SceneTree
## Structural/adversarial fixtures. Relocations here are NOT clean-run evidence.

var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func ticks(count: int) -> void:
	for index: int in count:
		await physics_frame

func run() -> void:
	var map: MapDefinition = MapCatalog.industrial()
	check(MapCatalog.validate_catalog(MapCatalog.official()).valid(), "Both official maps validate")
	check(map.sections.size() == 8 and map.checkpoints.size() == 7 and map.strict_order,
		"Full modular course with seven mandatory checkpoints")
	check(map.map_id != MapCatalog.training().map_id and map.difficulty_key == "UI_NORMAL",
		"Separate stable ID and Normal metadata")
	for kind: int in 9:
		var bad: MapDefinition = MapCatalog.industrial()
		match kind:
			0: bad.sections[3].transform.origin.x += 20
			1: bad.sections[2].transform.origin.x += 1
			2: bad.sections[4].next_id = &"s8"
			3: bad.checkpoints[3].respawn_anchor = ^"Missing"
			4: bad.sections[5].instance_id = &"s2"
			5: bad.camera_bounds.rectangle.size.x = -1
			6: bad.camera_zones.append(null)
			7: bad.start.section_id = &"s8"
			8: bad.sections[0].transform.x.x = 2
		check(not MapValidator.inspect(bad, false).valid(), "Industrial structural mutation %d" % kind)
	var tampered: MapDefinition = MapCatalog.industrial()
	tampered.declared_checksum = "0".repeat(64)
	check(MapValidator.inspect(tampered).message_key() == "MAP_CHECKSUM_ERROR", "Stale checksum refused")
	tampered = MapCatalog.industrial()
	tampered.camera_bounds.rectangle.position.x -= 20
	check(tampered.checksum() != map.checksum(), "Authored camera participates in identity")
	for missing: StringName in map.checkpoint_ids:
		var progress := CheckpointProgress.new()
		progress.configure(map.checkpoint_ids, map.mandatory_ids, true)
		for id: StringName in map.checkpoint_ids:
			if id != missing:
				progress.activate(id)
		check(not progress.can_finish(), "Shortcut cannot omit " + str(missing))
	var folder: String = OS.get_cache_dir().path_join("pv-m14-fixtures-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(folder)
	check(store.open(), "Isolated save")
	var legacy := TrialRecords.new(store, MapCatalog.training())
	legacy.definition.map_version = 2
	legacy.checksum = "6b8576e0a8e0f1c9f4d5ea815120e7e7ea61b759a877ef3d2891794804158c16"
	check(legacy.complete(600, [200, 400], true).saved, "Pre-M14 Training PB fixture")
	var old_key: String = legacy.key()
	var layer := InputLayer.new()
	layer.watch_hardware = false
	root.add_child(layer)
	var trial := SoloTrial.new()
	trial.layer = layer
	trial.records = TrialRecords.new(store, map)
	root.add_child(trial)
	await ticks(3)
	check(trial.phase == SoloTrial.Phase.HINT and trial.course.validate_respawns(), "Every capsule has safe static support")
	trial.dismiss_hint()
	await ticks(181)
	check(not trial.course.lifecycle.finish(), "Real Finish authority rejects untouched route")
	for point: MapPoint in map.checkpoints:
		var anchor: Vector2 = trial.course.assembly.point_position(point, true)
		check(trial.course.lifecycle.checkpoint(point.point_id, anchor), "Authority activates " + str(point.point_id))
		trial.course.player.respawn_at(anchor, true)
		await ticks(46)
		check(trial.course.player.die(), "Ordinary checkpoint death")
		await ticks(31)
		check(trial.course.player.position.distance_to(anchor) < 4 and trial.valid,
			"Safe actual lifecycle respawn " + str(point.point_id))
	# Occupy the last checkpoint capsule: fallback must use safe Start, not the blocker.
	var obstruction := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(60, 80)
	shape.shape = rectangle
	obstruction.add_child(shape)
	obstruction.position = trial.course.lifecycle.respawn_position
	trial.course.add_child(obstruction)
	await ticks(46)
	check(trial.course.player.die(), "Fallback death")
	await ticks(31)
	check(trial.course.player.position.distance_to(trial.course.lifecycle.start_position) < 4,
		"Obstructed checkpoint falls back to Start")
	obstruction.free()
	var prior: int = trial.elapsed
	paused = true
	await ticks(5)
	check(trial.elapsed == prior and trial.valid, "New map pause freezes eligible clock")
	paused = false
	check(trial.course.lifecycle.finish(), "All mandatory checkpoints authorize Finish")
	check(trial.result.saved and trial.records.best().total == trial.elapsed, "Independent new-map PB")
	check(store.data.trial_records.has(old_key) and store.data.save_version == 5, "Existing PB and schema survive")
	check(trial.course.world.active_count() == 0, "Finish drains pool")
	trial.request_retry()
	await ticks(3)
	var node_count: int = get_node_count()
	for attempt: int in 6:
		trial.request_retry()
		await ticks(3)
		check(get_node_count() == node_count and trial.splits.is_empty() and trial.deaths == 0,
			"Retry resets dynamic map without accumulating nodes")
	Input.action_press(layer.action_name("restart"))
	await ticks(30)
	var course_id: int = trial.course.get_instance_id()
	await ticks(40)
	check(trial.course.get_instance_id() == course_id, "Held restart fires once")
	Input.action_release(layer.action_name("restart"))
	await ticks(181)
	# Fixture placement after GO, without granting respawn invulnerability inside a pit.
	trial.course.player.position = map.death_bounds.get_center()
	await ticks(80)
	check(trial.deaths == 1 and trial.course.player.position.distance_to(
		trial.course.lifecycle.start_position) < 4, "Actual fall DeathZone returns to safe Start")
	for outside: Vector2 in [Vector2(-2000, 1300), Vector2(43600, 1300)]:
		var previous_deaths: int = trial.deaths
		trial.course.player.position = outside
		await ticks(80)
		check(trial.deaths == previous_deaths + 1 and trial.course.player.position.distance_to(
			trial.course.lifecycle.start_position) < 4, "Outward airborne escape still reaches fall zone")
	trial.free()
	var ui := AppUI.new()
	ui.store = store
	ui.input_layer = layer
	root.add_child(ui)
	ui.show_maps()
	# Five-entry layout fixture; the production catalog still contains two real maps.
	var back: Control = ui.column.get_child(ui.column.get_child_count() - 1)
	for index: int in 3:
		ui._map_card(MapCatalog.training())
	ui.column.move_child(back, ui.column.get_child_count() - 1)
	root.content_scale_size = Vector2i(1920, 1080)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	await ticks(20)
	var scroll: ScrollContainer = ui.column.get_parent()
	var fifth: Control = ui.column.get_child(4)
	check(scroll.get_global_rect().encloses(fifth.get_global_rect())
		and scroll.get_global_rect().encloses(back.get_global_rect()),
		"Five map cards and Back fit without scrolling at default UI scale")
	fifth.grab_focus()
	await ticks(2)
	check(scroll.scroll_vertical == 0 and fifth.get_focus_neighbor(SIDE_BOTTOM) == fifth.get_path_to(back),
		"Fifth card focus stays visible and navigates to Back")
	if "--capture" in OS.get_cmdline_user_args():
		await ticks(20)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://builds/m14/map-select.png")
	var first_card: Control = ui.column.get_child(0)
	var click_position := Vector2(first_card.get_global_rect().end.x - 40,
		first_card.get_global_rect().get_center().y)
	for pressed: bool in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = click_position
		click.pressed = pressed
		root.push_input(click, true)
		await process_frame
	await ticks(3)
	check(is_instance_valid(ui.trial) and ui.trial.records.definition.map_id == map.map_id
		and ui.trial.phase == SoloTrial.Phase.HINT, "Clicking the card preview opens new map with hint")
	ui.show_menu()
	check(not is_instance_valid(ui.trial), "Map select/menu unload owns whole course")
	ui.free()
	layer.free()
	for name: String in DirAccess.get_files_at(folder):
		DirAccess.remove_absolute(folder.path_join(name))
	DirAccess.remove_absolute(folder)
	if failures == 0:
		print("PROJECTVELOCITY_M14_MAP_OK checks=%d" % checks)
	quit(0 if failures == 0 else 1)
