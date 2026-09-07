class_name CameraBounds
extends Resource
## Axis-aligned map rectangle in world coordinates; clamps the entire visible viewport.

@export var enabled: bool = true
@export var rectangle := Rect2(-1000, -1000, 4500, 2700)


func valid() -> bool:
	return rectangle.position.is_finite() and rectangle.size.is_finite() and (
		rectangle.size.x > 0 and rectangle.size.y > 0)


func constrain(center: Vector2, visible_size: Vector2) -> Vector2:
	if not enabled:
		return center
	var half: Vector2 = visible_size / 2
	var result: Vector2 = center
	for axis: int in 2:
		if rectangle.size[axis] <= visible_size[axis]:
			result[axis] = rectangle.get_center()[axis]
		else:
			result[axis] = clampf(center[axis], rectangle.position[axis] + half[axis], rectangle.end[axis] - half[axis])
	return result
