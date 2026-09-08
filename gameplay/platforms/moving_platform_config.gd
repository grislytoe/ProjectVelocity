class_name MovingPlatformConfig
extends PlatformConfig

@export var route := PackedVector2Array([Vector2.ZERO, Vector2(400, 0)])
@export_range(1.0, 2000.0) var speed: float = 160.0
## One wait in seconds per route point; empty means no waits.
@export var waits := PackedFloat32Array([0.5, 0.5])
@export var loop: bool = true
@export var ping_pong: bool = true
@export var reverse: bool = false


func validate() -> bool:
	if not super.validate() or route.size() < 2 or not is_finite(speed) or speed <= 0:
		return false
	if not waits.is_empty() and waits.size() != route.size():
		return false
	for point: Vector2 in route:
		if not point.is_finite():
			return false
	for wait: float in waits:
		if not is_finite(wait) or wait < 0:
			return false
	for index: int in range(1, route.size()):
		if route[index].is_equal_approx(route[index - 1]):
			return false
	return true
