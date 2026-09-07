class_name TestPlayground
extends Node2D
## No saves or production hooks. Exactly one station owns collisions at any time.

const RESTART_HOLD_TICKS: int = 60
var stations: Array[PlaygroundStation] = PlaygroundStation.catalog()
var station_index: int = 0
var geometry: Node2D
var player: PlayerController
var layer: InputLayer
var camera: LocalPlayerCamera
var selector: OptionButton
var hint: Label
var diagnostics: Label
var controls: Label
var peak_speed: float = 0.0
var peak_fall: float = 0.0
var peak_rise: float = 0.0
var station_ticks: int = 0
var restart_ticks: int = 0
var _pending_station: int = -1
var _pending_action: String = ""
var _original_collision_hint: bool = false


func _ready() -> void:
	if not BuildInfo.is_development():
		set_process(false)
		set_physics_process(false)
		set_process_unhandled_input(false)
		queue_free()
		return
	_original_collision_hint = get_tree().debug_collisions_hint
	process_physics_priority = -100
	layer = InputLayer.new()
	add_child(layer)
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.input_layer = layer
	player.input_provider = sample_input
	add_child(player)
	camera = LocalPlayerCamera.new()
	camera.map_bounds = CameraBounds.new()
	add_child(camera)
	camera.follow_local(player)
	build_hud()
	activate_station(0)


func activate_station(index: int) -> void:
	station_index = posmod(index, stations.size())
	var station: PlaygroundStation = stations[station_index]
	if is_instance_valid(geometry):
		# Remove synchronously between physics steps: no stale collision bodies next tick.
		geometry.free()
	geometry = Node2D.new()
	add_child(geometry)
	for rectangle: Rect2 in station.boxes:
		add_polygon(PackedVector2Array([rectangle.position,
			Vector2(rectangle.end.x, rectangle.position.y), rectangle.end,
			Vector2(rectangle.position.x, rectangle.end.y)]))
	for points: PackedVector2Array in station.polygons:
		add_polygon(points)
	add_rulers(station)
	camera.map_bounds.rectangle = station.envelope
	layer.clear_transient_state()
	restart_ticks = 0
	reset_player()
	selector.select(station_index)
	hint.text = tr("M6_" + station.id + "_HINT")


func reset_player() -> void:
	player.respawn_at(stations[station_index].spawn)
	peak_speed = 0.0
	peak_fall = 0.0
	peak_rise = 0.0
	station_ticks = 0


func request_station(index: int) -> void:
	_pending_station = posmod(index, stations.size())


func request_action(action: String) -> void:
	_pending_action = action


func _physics_process(_delta: float) -> void:
	# Mutations happen before the player, never while physics is flushing queries.
	if _pending_station >= 0:
		activate_station(_pending_station)
		_pending_station = -1
	match _pending_action:
		"respawn":
			reset_player()
		"death":
			player.die(true)
		"restore":
			player.motor.double_jump_available = true
			player.motor.dash_available = true
			player.publish_visuals()
		"collision":
			get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint
			for body: Node in geometry.get_children():
				if body is StaticBody2D:
					(body.get_child(0) as CollisionPolygon2D).queue_redraw()
	_pending_action = ""
	station_ticks += 1
	peak_speed = maxf(peak_speed, absf(player.velocity.x))
	peak_fall = maxf(peak_fall, player.velocity.y)
	peak_rise = maxf(peak_rise, stations[station_index].spawn.y - player.position.y)


func _exit_tree() -> void:
	get_tree().debug_collisions_hint = _original_collision_hint


func sample_input() -> InputFrame:
	var frame: InputFrame = layer.sample()
	restart_ticks = mini(restart_ticks + 1, RESTART_HOLD_TICKS + 1) if frame.restart_held else 0
	if restart_ticks == RESTART_HOLD_TICKS or not stations[station_index].envelope.has_point(player.position):
		reset_player()
		return InputFrame.new()
	return frame


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_PAGEUP: request_station(station_index - 1)
			KEY_PAGEDOWN: request_station(station_index + 1)
			KEY_F6: request_action("death")
			KEY_F7: request_action("respawn")
			KEY_F8: request_action("restore")
			KEY_F9: request_action("collision")
			_: return
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_DPAD_LEFT:
			request_station(station_index - 1)
		elif event.button_index == JOY_BUTTON_DPAD_RIGHT:
			request_station(station_index + 1)
		else:
			return
		get_viewport().set_input_as_handled()


func build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 20)
	panel.custom_minimum_size = Vector2(1600, 0)
	canvas.add_child(panel)
	var column := VBoxContainer.new()
	column.theme = Theme.new()
	column.theme.default_font_size = 20
	panel.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	add_button(row, "M6_PREVIOUS", func() -> void: request_station(station_index - 1))
	selector = OptionButton.new()
	selector.focus_mode = Control.FOCUS_NONE
	for station: PlaygroundStation in stations:
		selector.add_item(tr("M6_" + station.id))
	selector.item_selected.connect(request_station)
	row.add_child(selector)
	add_button(row, "M6_NEXT", func() -> void: request_station(station_index + 1))
	add_button(row, "M6_RESET", request_action.bind("respawn"))
	add_button(row, "M6_DEATH", request_action.bind("death"))
	add_button(row, "M6_RESTORE", request_action.bind("restore"))
	add_button(row, "M6_COLLISION", request_action.bind("collision"))
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 22)
	column.add_child(hint)
	controls = Label.new()
	column.add_child(controls)
	diagnostics = Label.new()
	column.add_child(diagnostics)


func add_button(row: HBoxContainer, key: String, action: Callable) -> void:
	var button := Button.new()
	button.text = tr(key)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	row.add_child(button)


func _process(_delta: float) -> void:
	if player == null:
		return
	controls.text = tr("M6_CONTROLS") % [layer.prompt("jump").get("label", ""),
		layer.prompt("dash").get("label", ""), layer.prompt("restart").get("label", "")]
	diagnostics.text = tr("M6_DIAGNOSTICS") % [player.motor.machine.label(), player.position.x,
		player.position.y, player.velocity.x, player.velocity.y, player.contacts.grounded,
		player.contacts.wall_normal != Vector2.ZERO, player.motor.double_jump_available,
		player.motor.dash_available, player.motor.coyote_ticks, player.motor.dash_ticks,
		player.motor.wall_lock_ticks, player.motor.end_lag_ticks, station_ticks,
		peak_speed, peak_fall, peak_rise, restart_ticks / 60.0]


func add_polygon(points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionPolygon2D.new()
	collision.polygon = points
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = points
	visual.color = Color("294653")
	body.add_child(visual)
	geometry.add_child(body)


func add_rulers(station: PlaygroundStation) -> void:
	# Reference grid remains non-colliding. Numbers are world pixels, not game scores.
	for x: int in range(int(station.envelope.position.x), int(station.envelope.end.x), 200):
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(x, station.envelope.position.y), Vector2(x, station.envelope.end.y)])
		line.default_color = Color(0.2, 0.5, 0.6, 0.16)
		line.width = 1.0
		geometry.add_child(line)
		add_marker(Vector2(x, 590), str(x))
	for y: int in range(int(station.envelope.position.y), 501, 100):
		var line := Line2D.new()
		line.points = PackedVector2Array([Vector2(-300, y), Vector2(300, y)])
		line.default_color = Color(0.4, 0.8, 0.7, 0.3)
		line.width = 1.0
		geometry.add_child(line)
		add_marker(Vector2(-380, y - 24), str(500 - y))
	add_marker(station.spawn + Vector2(-45, 45), tr("M6_SPAWN"))
	if station.id == "DASH":
		for index: int in 8:
			var direction := Vector2.RIGHT.rotated(index * PI / 4.0)
			var line := Line2D.new()
			line.points = PackedVector2Array([Vector2(0, 150), Vector2(0, 150) + direction * 220])
			line.default_color = Color(0.9, 0.7, 0.2, 0.6)
			geometry.add_child(line)


func add_marker(location: Vector2, value: String) -> void:
	var label := Label.new()
	label.position = location
	label.text = value
	label.add_theme_color_override("font_color", Color("7fafbc"))
	geometry.add_child(label)
