class_name RespawnSafety
extends RefCounted
## Conservative static-floor contract. Full capsule clearance and fatal-area exclusion.

static func valid(player: PlayerController, position: Vector2) -> bool:
	if not position.is_finite() or not player.is_inside_tree():
		return false
	var collision := player.get_node("CollisionShape2D") as CollisionShape2D
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = collision.shape
	query.transform = player.global_transform
	query.transform.origin = position
	query.transform = query.transform * collision.transform
	query.collision_mask = player.collision_mask | 4
	query.collide_with_areas = true
	query.exclude = [player.get_rid()]
	var space: PhysicsDirectSpaceState2D = player.get_world_2d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return false
	query.transform.origin.y += 4.0
	query.collision_mask = player.collision_mask
	query.collide_with_areas = false
	var supports: Array[Dictionary] = space.intersect_shape(query, 8)
	if supports.is_empty():
		return false
	for hit: Dictionary in supports:
		var body: Object = hit.collider
		if not body is StaticBody2D or body is AnimatableBody2D:
			return false
		var floor_body := body as StaticBody2D
		if not floor_body.constant_linear_velocity.is_zero_approx() or not is_zero_approx(floor_body.constant_angular_velocity):
			return false
	return true
