class_name CameraZone
extends Resource
## Extensible authored region. No physics body, camera ownership or gameplay effects.

@export var zone_id: String = "zone"
@export var enabled: bool = true
@export var priority: int = 0
@export var rectangle := Rect2(0, 0, 400, 400)
@export var zoom_multiplier: float = 1.0
@export var additional_offset: Vector2 = Vector2.ZERO
@export var look_ahead_multiplier: float = 1.0
@export var lock_enabled: bool = false
@export var lock_position: Vector2 = Vector2.ZERO


func valid() -> bool:
	return not zone_id.is_empty() and rectangle.position.is_finite() and rectangle.size.is_finite() and (
		rectangle.size.x > 0 and rectangle.size.y > 0 and additional_offset.is_finite() and
		lock_position.is_finite() and is_finite(zoom_multiplier) and zoom_multiplier > 0 and
		is_finite(look_ahead_multiplier) and look_ahead_multiplier >= 0)


func contains(point: Vector2, margin: float = 0.0) -> bool:
	return enabled and rectangle.grow(margin).has_point(point)
