class_name PlatformVisual
extends Node2D
## Shape/marking grammar layered over the authoritative collision polygon.

var polygon := PackedVector2Array()
var kind: String = "static"


func configure(points: PackedVector2Array, platform_kind: String) -> void:
	polygon = points
	kind = platform_kind
	queue_redraw()


func _draw() -> void:
	if polygon.is_empty():
		return
	var bounds := _bounds()
	var top_y: float = bounds.position.y
	match kind:
		"one_way":
			for x: float in range(int(bounds.position.x), int(bounds.end.x), 22):
				draw_line(Vector2(x, top_y), Vector2(minf(x + 13, bounds.end.x), top_y), ArtPalette.ROUTE, 4, true)
				draw_line(Vector2(x + 6, top_y + 5), Vector2(x + 11, top_y + 10), ArtPalette.ROUTE_DIM, 2, true)
		"moving":
			draw_line(Vector2(bounds.position.x, top_y), Vector2(bounds.end.x, top_y), ArtPalette.READY, 5, true)
			var center := bounds.get_center()
			for direction: float in [-1.0, 1.0]:
				var p := center + Vector2(direction * 20, 1)
				draw_polyline(PackedVector2Array([p + Vector2(-direction * 8, -7), p,
					p + Vector2(-direction * 8, 7)]), ArtPalette.READY, 2, true)
		"breakable":
			draw_line(Vector2(bounds.position.x, top_y), Vector2(bounds.end.x, top_y), ArtPalette.WARNING, 4, true)
			for x: float in range(int(bounds.position.x + 18), int(bounds.end.x), 34):
				draw_polyline(PackedVector2Array([Vector2(x, top_y + 3), Vector2(x - 5, top_y + 10),
					Vector2(x + 4, top_y + 17)]), ArtPalette.WARNING.darkened(0.25), 2, true)
		"jump_pad":
			draw_line(Vector2(bounds.position.x, top_y), Vector2(bounds.end.x, top_y), ArtPalette.FOCUS, 6, true)
			for x: float in range(int(bounds.position.x + 10), int(bounds.end.x - 5), 24):
				draw_line(Vector2(x, top_y + 7), Vector2(x + 9, top_y + 16), ArtPalette.FOCUS, 3, true)
		_:
			draw_line(Vector2(bounds.position.x, top_y), Vector2(bounds.end.x, top_y), ArtPalette.ROUTE, 4, true)
			for x: float in range(int(bounds.position.x + 12), int(bounds.end.x), 48):
				draw_circle(Vector2(x, top_y + 12), 2.0, ArtPalette.TEXT_MUTED)


func _bounds() -> Rect2:
	var result := Rect2(polygon[0], Vector2.ZERO)
	for point: Vector2 in polygon:
		result = result.expand(point)
	return result
