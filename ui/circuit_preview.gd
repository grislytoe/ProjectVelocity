class_name CircuitPreview
extends Control
## Schematic illustration of the available circuit, not additional map data.

func _ready() -> void:
	custom_minimum_size.y = 240
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("09151e"))
	for index: int in 24:
		var x: float = float(index) * size.x / 24.0
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("19303c"))
	var route := PackedVector2Array([
		Vector2(0.05, 0.75), Vector2(0.22, 0.75), Vector2(0.29, 0.38),
		Vector2(0.43, 0.38), Vector2(0.51, 0.62), Vector2(0.66, 0.62),
		Vector2(0.77, 0.26), Vector2(0.94, 0.26)])
	for index: int in route.size():
		route[index] *= size
	draw_polyline(route, Color("73e7d2"), 5, true)
	for index: int in [0, 3, 5, 7]:
		draw_circle(route[index], 10, Color("edc675"))
