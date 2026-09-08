class_name TurretConfig
extends Resource

@export var detection_range: float = 1100.0
@export var fire_range: float = 900.0
## Radians per second.
@export var aim_turn_speed: float = 3.0
@export var aim_tolerance: float = 0.06
@export var telegraph_duration: float = 0.5
@export var cooldown: float = 1.0
@export var minimum_cooldown: float = 0.25
@export var projectile_speed: float = 816.0 # 680 base run speed * 1.2
@export var projectile_radius: float = 5.0
@export var projectile_lifetime: float = 5.0
@export var aim_lead_factor: float = 0.7
@export var maximum_lead_time: float = 0.5
@export var maximum_lead_distance: float = 180.0
@export var barrel_offsets := PackedVector2Array([Vector2(-12, -14), Vector2(12, 14)])


func validate() -> bool:
	for value: float in [detection_range, fire_range, aim_turn_speed, aim_tolerance,
		telegraph_duration, cooldown, minimum_cooldown, projectile_speed, projectile_radius,
		projectile_lifetime, maximum_lead_time, maximum_lead_distance]:
		if not is_finite(value) or value <= 0:
			return false
	return fire_range <= detection_range and aim_tolerance <= PI \
		and is_finite(aim_lead_factor) and aim_lead_factor >= 0 and aim_lead_factor <= 1 \
		and barrel_offsets.size() == 2 and barrel_offsets[0].is_finite() \
		and barrel_offsets[1].is_finite()


func lead_point(origin: Vector2, target_position: Vector2, target_velocity: Vector2) -> Vector2:
	var travel: float = minf(origin.distance_to(target_position) / projectile_speed,
		maximum_lead_time)
	return target_position + (target_velocity * travel * aim_lead_factor).limit_length(
		maximum_lead_distance)
