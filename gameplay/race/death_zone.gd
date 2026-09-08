class_name DeathZone
extends Area2D
## Rechecks persistent overlaps so expiry inside a hazard cannot grant immunity forever.

func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	process_physics_priority = 25


func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		if body is PlayerController:
			(body as PlayerController).die()
