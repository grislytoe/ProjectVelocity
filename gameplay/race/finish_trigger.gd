class_name FinishTrigger
extends Area2D

var players: Dictionary = {}


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_entered)


func _entered(body: Node2D) -> void:
	if players.has(body):
		(players[body] as PlayerLifecycle).finish()
