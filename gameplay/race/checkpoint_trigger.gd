class_name CheckpointTrigger
extends Area2D

@export var checkpoint_id: StringName
@export var respawn_anchor: Marker2D
var players: Dictionary = {}
var activated_players: Dictionary = {}
var local_active: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_entered)


func _entered(body: Node2D) -> void:
	if not players.has(body) or not is_instance_valid(respawn_anchor):
		return
	var lifecycle: PlayerLifecycle = players[body]
	if lifecycle.checkpoint(checkpoint_id, respawn_anchor.global_position):
		activated_players[body] = true
		if lifecycle.player.presentation != null and lifecycle.player.presentation.is_local:
			local_active = true
		queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, 212), Vector2(0, -298), Color.CYAN, 4)
	draw_circle(Vector2(0, -293), 12, Color.CYAN, local_active, -1 if local_active else 2)
