class_name RobotPart
extends Node2D
## Replaceable vector-art module: no gameplay or collision responsibilities.

var size := Vector2(12, 18)
var body_color := Color("44ccee")
var accent_color := Color.WHITE
var outline_color := Color("d8eaf0")
var outline_width: float = 1.2
var emission: float = 1.0
var visor: bool = false


func _draw() -> void:
	var half: Vector2 = size / 2
	var bevel: float = minf(3.0, half.x * 0.4)
	var points := PackedVector2Array([
		Vector2(-half.x + bevel, -half.y), Vector2(half.x - bevel, -half.y),
		Vector2(half.x, -half.y + bevel), Vector2(half.x, half.y - bevel),
		Vector2(half.x - bevel, half.y), Vector2(-half.x + bevel, half.y),
		Vector2(-half.x, half.y - bevel), Vector2(-half.x, -half.y + bevel)])
	draw_colored_polygon(points, body_color)
	if outline_width > 0:
		var contour: PackedVector2Array = points.duplicate()
		contour.append(points[0])
		draw_polyline(contour, outline_color, outline_width, true)
	draw_line(Vector2(-half.x + 3, half.y - 4), Vector2(half.x - 3, half.y - 4), body_color.darkened(0.4), 2, true)
	var light: Color = accent_color.lerp(body_color.darkened(0.65), 1.0 - emission)
	if visor:
		draw_rect(Rect2(-half.x + 3, -3, size.x - 6, 6), Color("101c29"))
		draw_line(Vector2(-half.x + 5, 0), Vector2(half.x - 5, 0), light, 2, true)
	else:
		draw_circle(Vector2(0, -half.y + 5), 2, light, true, -1, true)
