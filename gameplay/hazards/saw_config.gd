class_name SawConfig
extends Resource

@export_range(1.0, 500.0) var radius: float = 36.0
@export var moving: bool = false
## Reuses M8 route speed, waits, loop, ping-pong and reverse authoring.
@export var path: MovingPlatformConfig = preload("res://gameplay/platforms/default_moving.tres")


func validate() -> bool:
	return is_finite(radius) and radius > 0 and (not moving or (path != null and path.validate()))
