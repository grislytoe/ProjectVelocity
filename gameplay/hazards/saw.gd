class_name Saw
extends DeathZone

@export var config: SawConfig = preload("res://gameplay/hazards/default_saw.tres")
var elapsed_ticks: int = 0
var route: PlatformRoute
var _origin: Vector2


func _ready() -> void:
	super._ready()
	if config == null or not config.validate():
		push_error("Invalid saw config")
		hide()
		set_physics_process(false)
		return
	_origin = position
	var shape := CircleShape2D.new()
	shape.radius = config.radius
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	if config.moving:
		route = PlatformRoute.new(config.path)
		position = _origin + route.sample(0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if route != null:
		position = _origin + route.sample(elapsed_ticks)
		elapsed_ticks += 1
	super._physics_process(delta)


func _draw() -> void:
	var teeth := PackedVector2Array()
	for index: int in 24:
		var tooth_radius: float = config.radius if index % 2 == 0 else config.radius * 0.78
		teeth.append(Vector2.RIGHT.rotated(index * TAU / 24.0) * tooth_radius)
	draw_colored_polygon(teeth, ArtPalette.DANGER)
	var contour := teeth.duplicate()
	contour.append(teeth[0])
	draw_polyline(contour, Color(1, 0.82, 0.82), 2, true)
	draw_circle(Vector2.ZERO, config.radius * 0.55, ArtPalette.STEEL_DARK)
	draw_circle(Vector2.ZERO, config.radius * 0.20, ArtPalette.WARNING)
	for index: int in 8:
		var direction := Vector2.RIGHT.rotated(index * TAU / 8.0)
		draw_line(direction * config.radius * 0.27, direction * config.radius * 0.51,
			ArtPalette.TEXT_MUTED, 3, true)
