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


func _draw() -> void:
	# Twin uprights and a check pattern read as Finish without a minimap or color dependency.
	draw_line(Vector2(-34, 220), Vector2(-34, -305), ArtPalette.FOCUS, 6, true)
	draw_line(Vector2(34, 220), Vector2(34, -305), ArtPalette.FOCUS, 6, true)
	draw_line(Vector2(-34, -305), Vector2(34, -305), ArtPalette.FOCUS, 6, true)
	for row: int in 3:
		for column: int in 4:
			var color := ArtPalette.TEXT if (row + column) % 2 == 0 else ArtPalette.BACKGROUND
			draw_rect(Rect2(-30 + column * 15, -298 + row * 15, 15, 15), color)
	draw_polyline(PackedVector2Array([Vector2(-48, 220), Vector2(0, 202), Vector2(48, 220)]),
		ArtPalette.FOCUS, 4, true)
