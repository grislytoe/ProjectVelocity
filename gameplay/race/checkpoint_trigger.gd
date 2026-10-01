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
	var color := ArtPalette.READY if local_active else ArtPalette.ROUTE
	draw_line(Vector2(0, 212), Vector2(0, -284), ArtPalette.STEEL, 7, true)
	draw_line(Vector2(0, 212), Vector2(0, -284), color, 3, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -286), Vector2(30, -268),
		Vector2(0, -250), Vector2(-30, -268)]), Color(color.r, color.g, color.b, 0.22))
	draw_polyline(PackedVector2Array([Vector2(0, -286), Vector2(30, -268),
		Vector2(0, -250), Vector2(-30, -268), Vector2(0, -286)]), color, 3, true)
	if local_active:
		draw_circle(Vector2(0, -268), 7, color)
		draw_arc(Vector2.ZERO, 28, PI * 1.12, PI * 1.88, 10, color, 3, true)
	else:
		draw_circle(Vector2(0, -268), 7, color, false, 2, true)
