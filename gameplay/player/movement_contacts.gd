class_name MovementContacts
extends RefCounted
## Collision facts supplied by the body adapter, reusable by pure state tests.

var grounded: bool = false
var wall_normal: Vector2 = Vector2.ZERO
var steep_normal: Vector2 = Vector2.ZERO


func clear() -> void:
	grounded = false
	wall_normal = Vector2.ZERO
	steep_normal = Vector2.ZERO


func has_wall() -> bool:
	return not wall_normal.is_zero_approx()
