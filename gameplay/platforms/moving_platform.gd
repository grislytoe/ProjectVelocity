class_name MovingPlatform
extends AnimatableBody2D

@export var config: MovingPlatformConfig = preload("res://gameplay/platforms/default_moving.tres")
var route: PlatformRoute
var elapsed_ticks: int = 0
var _origin: Vector2


func _ready() -> void:
	process_physics_priority = -50
	if config == null or not config.validate():
		push_error("Invalid moving platform config")
		set_physics_process(false)
		return
	PlatformGeometry.build(self, config)
	route = PlatformRoute.new(config)
	_origin = position
	position = _origin + route.sample(0)
	reset_physics_interpolation()


func _physics_process(_delta: float) -> void:
	elapsed_ticks += 1
	position = _origin + route.sample(elapsed_ticks)
