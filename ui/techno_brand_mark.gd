class_name TechnoBrandMark
extends Control
## Code-native mark: resolution-independent and safe for RU/EN layouts.


func _ready() -> void:
	custom_minimum_size = Vector2(180, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var y: float = size.y * 0.5
	draw_line(Vector2(0, y), Vector2(46, y), ArtPalette.ROUTE_DIM, 3, true)
	draw_polyline(PackedVector2Array([Vector2(48, y - 8), Vector2(62, y), Vector2(48, y + 8)]),
		ArtPalette.ROUTE, 4, true)
	draw_line(Vector2(67, y), Vector2(132, y), ArtPalette.ROUTE, 4, true)
	draw_polyline(PackedVector2Array([Vector2(134, y - 8), Vector2(149, y), Vector2(134, y + 8)]),
		ArtPalette.FOCUS, 4, true)
	draw_line(Vector2(154, y), Vector2(180, y), ArtPalette.FOCUS, 3, true)
