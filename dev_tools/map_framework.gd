extends Node2D
## F6 developer overview. Number keys inspect accepted and rejected definitions.

var definition: MapDefinition
var course: SoloCourse
var layer: InputLayer
var label: Label
var camera: Camera2D

func _ready() -> void:
	layer = InputLayer.new()
	layer.watch_hardware = false
	add_child(layer)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(30, 24)
	label.add_theme_font_size_override("font_size", 26)
	canvas.add_child(label)
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	camera.position = Vector2(2100, 450)
	camera.zoom = Vector2.ONE * 0.4
	add_child(camera)
	show_fixture(1)
	if "--capture" in OS.get_cmdline_user_args():
		capture.call_deferred()

func show_fixture(index: int) -> void:
	if is_instance_valid(course):
		course.free()
	definition = MapCatalog.training()
	if index == 2:
		definition.sections.resize(1)
		definition.sections[0].next_id = &""
		definition.checkpoints.clear()
		definition.finish.section_id = &"first"
		definition.finish.anchor = ^"Checkpoint"
		definition.declared_checksum = definition.checksum()
	elif index == 3:
		definition.sections[1].transform.origin.x += 20
	elif index == 4:
		definition.start.respawn_anchor = ^"Missing"
	elif index == 5:
		definition.declared_checksum = "bad"
	var report: MapDiagnostics = MapValidator.inspect(definition)
	label.text = "M13 / 1: Training  2: Single section  3: Gap  4: Missing anchor  5: Hash mismatch\n"
	label.text += "Grid: 20 world px / cyan: entrance / gold: exit / green: respawn\n"
	if report.valid():
		course = SoloCourse.new()
		course.input_layer = layer
		course.definition = definition
		add_child(course)
		course.process_mode = Node.PROCESS_MODE_DISABLED
		for child: Node in course.get_children():
			if child is Camera2D:
				child.enabled = false
		label.text += "Accepted structure / physics safety is checked separately on Solo entry"
	else:
		label.text += "REJECTED before activation\n" + report.describe()
	camera.make_current()
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_5:
			show_fixture.call_deferred(event.physical_keycode - KEY_1 + 1)

func _draw() -> void:
	if definition == null:
		return
	for x: int in range(0, 4201, 20):
		draw_line(Vector2(x, 100), Vector2(x, 740), Color(0.16, 0.32, 0.38, 0.6),
			4 if x % 100 == 0 else 2.5, true)
	for y: int in range(100, 741, 20):
		draw_line(Vector2(0, y), Vector2(4200, y), Color(0.16, 0.32, 0.38, 0.6),
			4 if y % 100 == 0 else 2.5, true)
	if not is_instance_valid(course):
		return
	for placement: MapSectionPlacement in definition.sections:
		var section: Node2D = course.assembly.sections[placement.instance_id]
		for path: NodePath in [placement.section.entrance, placement.section.exit]:
			var marker := section.get_node(path) as Marker2D
			var point: Vector2 = placement.transform * MapValidator.relative_transform(marker, section).origin
			draw_circle(point, 22 if path == placement.section.entrance else 14,
				Color("3ecac9") if path == placement.section.entrance else Color("edc675"), false, 4)
	var points: Array[MapPoint] = [definition.start]
	points.append_array(definition.checkpoints)
	for point: MapPoint in points:
		draw_circle(course.assembly.point_position(point, true), 9, Color("8bee89"))

func capture() -> void:
	for index: int in range(1, 6):
		show_fixture(index)
		await get_tree().create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://builds/m13-map-framework-%d.png" % index)
	print("PROJECTVELOCITY_M13_RENDER_OK")
	get_tree().quit()
