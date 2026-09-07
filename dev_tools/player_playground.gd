extends Node2D
## Isolated developer fixture. No profile, save, progression or gameplay mode.

var player: PlayerController
var layer: InputLayer
var hud: Label
var profile: PlayerProfileData
var camera: LocalPlayerCamera
const RESTART_HOLD_TICKS: int = PlayerMovementConfig.PHYSICS_HZ
var _restart_ticks: int = 0


func _ready() -> void:
	layer = InputLayer.new()
	add_child(layer)
	box(Vector2(650, 650), Vector2(1700, 100))
	box(Vector2(-250, 300), Vector2(60, 700))
	box(Vector2(900, 370), Vector2(50, 460))
	box(Vector2(500, 410), Vector2(240, 30))
	box(Vector2(1200, 260), Vector2(270, 30))
	polygon(PackedVector2Array([Vector2(1500, 600), Vector2(1950, 360), Vector2(1950, 700), Vector2(1500, 700)]))
	polygon(PackedVector2Array([Vector2(2020, 700), Vector2(2250, 190), Vector2(2250, 800)]))
	box(Vector2(2350, 850), Vector2(1000, 100))
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.position = Vector2(150, 500)
	player.input_provider = sample_input
	player.input_layer = layer
	add_child(player)
	if profile != null:
		player.presentation.apply_profile(profile)
	camera = LocalPlayerCamera.new()
	camera.map_bounds = CameraBounds.new()
	add_child(camera)
	camera.follow_local(player)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Label.new()
	hud.position = Vector2(28, 24)
	hud.add_theme_font_size_override("font_size", 22)
	canvas.add_child(hud)


func sample_input() -> InputFrame:
	var frame: InputFrame = layer.sample()
	# One activation per uninterrupted hold; release rearms the action.
	_restart_ticks = mini(_restart_ticks + 1, RESTART_HOLD_TICKS + 1) if frame.restart_held else 0
	if _restart_ticks == RESTART_HOLD_TICKS or player.position.y > 1600:
		player.respawn_at(Vector2(150, 500))
	return frame


func _process(_delta: float) -> void:
	hud.text = tr("M3_PLAYGROUND") + "\n" + tr("M3_CONTROLS") % [
		layer.prompt("move_left").get("label", ""), layer.prompt("move_right").get("label", ""),
		layer.prompt("jump").get("label", ""), layer.prompt("dash_up").get("label", ""),
		layer.prompt("dash").get("label", ""), layer.prompt("restart").get("label", "")] + "\n%s  |  v=(%.0f, %.0f)  |  jump=%s dash=%s" % [
		player.motor.machine.label(), player.velocity.x, player.velocity.y,
		player.motor.double_jump_available, player.motor.dash_available]


func box(center: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var body := StaticBody2D.new()
	body.position = center
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-size / 2, Vector2(size.x, -size.y) / 2, size / 2, Vector2(-size.x, size.y) / 2])
	visual.color = Color("294653")
	body.add_child(visual)
	add_child(body)


func polygon(points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	var collision := CollisionPolygon2D.new()
	collision.polygon = points
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = points
	visual.color = Color("3a5960")
	body.add_child(visual)
	add_child(body)
