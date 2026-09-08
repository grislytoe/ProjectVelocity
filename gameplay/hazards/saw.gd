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
	draw_circle(Vector2.ZERO, config.radius, Color("ef394f"))
	draw_circle(Vector2.ZERO, config.radius * 0.4, Color("26333e"))
	for index: int in 12:
		var direction := Vector2.RIGHT.rotated(index * TAU / 12)
		draw_line(direction * config.radius * 0.6, direction * config.radius, Color.WHITE, 2)
