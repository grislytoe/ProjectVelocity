class_name StaticPlatform
extends StaticBody2D

@export var config: PlatformConfig = preload("res://gameplay/platforms/default_static.tres")
var surface: CollisionPolygon2D


func _ready() -> void:
	if config == null or not config.validate():
		push_error("Invalid platform config")
		return
	surface = PlatformGeometry.build(self, config)
