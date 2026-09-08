class_name PlatformConfig
extends Resource
## Local polygon permits rectangles and slopes without changing the collision adapter.

@export var polygon := PackedVector2Array([
	Vector2(-120, 0), Vector2(120, 0), Vector2(120, 24), Vector2(-120, 24)])
@export var color := Color("398698")
@export var one_way: bool = false
@export_range(1.0, 32.0) var one_way_margin: float = 4.0


func validate() -> bool:
	if polygon.size() < 3 or not is_finite(one_way_margin) or one_way_margin <= 0:
		return false
	for point: Vector2 in polygon:
		if not point.is_finite():
			return false
	return not Geometry2D.triangulate_polygon(polygon).is_empty()
