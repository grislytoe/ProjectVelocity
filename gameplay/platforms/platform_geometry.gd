class_name PlatformGeometry
extends RefCounted


static func build(body: PhysicsBody2D, config: PlatformConfig) -> CollisionPolygon2D:
	var shape := CollisionPolygon2D.new()
	shape.polygon = config.polygon
	shape.one_way_collision = config.one_way
	shape.one_way_collision_margin = config.one_way_margin
	body.add_child(shape)
	var visual := Polygon2D.new()
	visual.name = "Surface"
	visual.polygon = config.polygon
	visual.color = config.color
	body.add_child(visual)
	return shape
