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
var kind: String = "module"


func _draw() -> void:
	var half: Vector2 = size / 2
	var bevel: float = minf(4.0, half.x * 0.42)
	var points := _silhouette(half, bevel)
	# A dark under-panel gives the tiny modules material separation without texture noise.
	var shadow := points.duplicate()
	for index: int in shadow.size():
		shadow[index] += Vector2(0, 1.5)
	draw_colored_polygon(shadow, body_color.darkened(0.48))
	draw_colored_polygon(points, body_color)
	if outline_width > 0:
		var contour: PackedVector2Array = points.duplicate()
		contour.append(points[0])
		draw_polyline(contour, outline_color, outline_width, true)
	draw_line(Vector2(-half.x + 3, half.y - 4), Vector2(half.x - 3, half.y - 4), body_color.darkened(0.5), 2, true)
	var light: Color = accent_color.lerp(body_color.darkened(0.65), 1.0 - emission)
	if visor:
		draw_rect(Rect2(-half.x + 4, -4, size.x - 8, 7), ArtPalette.BACKGROUND)
		draw_line(Vector2(-half.x + 6, -0.5), Vector2(half.x - 6, -0.5), light, 2.5, true)
		draw_circle(Vector2(half.x - 7, -0.5), 1.5, Color.WHITE.lerp(light, 0.55))
	else:
		var marker := Vector2(0, -half.y + 5)
		if kind == "torso":
			draw_polyline(PackedVector2Array([marker + Vector2(-4, 0), marker + Vector2(0, 3),
				marker + Vector2(4, 0)]), light, 2.5, true)
		else:
			draw_circle(marker, 2, light, true, -1, true)
	if kind in ["left_arm", "right_arm", "left_leg", "right_leg"]:
		draw_circle(Vector2(0, half.y - 3), 1.4, light, true, -1, true)


func _silhouette(half: Vector2, bevel: float) -> PackedVector2Array:
	if kind == "head":
		return PackedVector2Array([Vector2(-half.x + 5, -half.y), Vector2(half.x - 3, -half.y),
			Vector2(half.x, -half.y + 4), Vector2(half.x - 2, half.y - 2),
			Vector2(half.x - 7, half.y), Vector2(-half.x + 3, half.y),
			Vector2(-half.x, half.y - 4), Vector2(-half.x, -half.y + 3)])
	if kind == "torso":
		return PackedVector2Array([Vector2(-half.x + 4, -half.y), Vector2(half.x - 4, -half.y),
			Vector2(half.x, -half.y + 6), Vector2(half.x - 3, half.y),
			Vector2(-half.x + 3, half.y), Vector2(-half.x, -half.y + 6)])
	return PackedVector2Array([Vector2(-half.x + bevel, -half.y), Vector2(half.x - bevel, -half.y),
		Vector2(half.x, -half.y + bevel), Vector2(half.x - 1, half.y - bevel),
		Vector2(half.x - bevel, half.y), Vector2(-half.x + bevel, half.y),
		Vector2(-half.x + 1, half.y - bevel), Vector2(-half.x, -half.y + bevel)])
