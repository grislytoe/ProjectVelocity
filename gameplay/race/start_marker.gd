class_name StartMarker
extends Node2D
## Presentation-only race origin marker.


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(-24, 32), Vector2(-24, -92), ArtPalette.ROUTE, 4, true)
	draw_line(Vector2(24, 32), Vector2(24, -92), ArtPalette.ROUTE, 4, true)
	draw_line(Vector2(-24, -92), Vector2(24, -92), ArtPalette.ROUTE, 4, true)
	for row: int in 2:
		for column: int in 4:
			var color := ArtPalette.TEXT if (row + column) % 2 == 0 else ArtPalette.STEEL_DARK
			draw_rect(Rect2(-20 + column * 10, -87 + row * 10, 10, 10), color)
	draw_polyline(PackedVector2Array([Vector2(-40, 34), Vector2(0, 20), Vector2(40, 34)]),
		ArtPalette.ROUTE_DIM, 3, true)
