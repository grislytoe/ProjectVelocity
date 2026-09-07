class_name PlayerMovementConfig
extends Resource
## Immutable per-controller tuning. Units: pixels, seconds, pixels/second.

const PHYSICS_HZ: int = 60
const STEP: float = 1.0 / PHYSICS_HZ

@export_group("Ground")
@export var ground_max_speed: float = 680.0
@export var ground_acceleration: float = 4800.0
@export var ground_deceleration: float = 5800.0
@export_group("Air")
@export var air_max_speed: float = 660.0
@export var air_acceleration: float = 2800.0
@export var air_deceleration: float = 1600.0
@export var rise_gravity: float = 1700.0
@export var fall_gravity: float = 2300.0
@export var terminal_velocity: float = 1400.0
@export_group("Jump")
@export var jump_force: float = 740.0
@export var second_jump_force: float = 680.0
@export var coyote_time: float = 0.1
@export var jump_cut_gravity_multiplier: float = 2.5
@export_group("Wall")
@export var wall_slide_speed: float = 100.0
@export var wall_slide_gravity_multiplier: float = 0.18
@export var wall_jump_horizontal_force: float = 520.0
@export var wall_jump_vertical_force: float = 720.0
@export var wall_jump_input_lock_time: float = 0.15
@export var wall_probe_distance: float = 2.0
@export var wall_normal_max_y: float = 0.15
@export_group("Dash")
@export var dash_speed: float = 1450.0
@export var dash_duration: float = 0.15
@export var dash_momentum_retention: float = 0.65
@export var dash_end_lag: float = 0.06
@export var dash_cancel_enabled: bool = false
@export_group("Slopes")
@export var slope_slide_angle_degrees: float = 45.0
@export var slope_gravity_multiplier: float = 1.2
@export var floor_snap_distance: float = 8.0
@export_group("Lifecycle")
@export var respawn_invulnerability: float = 0.75


static func ticks(seconds: float) -> int:
	return maxi(0, ceili(seconds * PHYSICS_HZ - 0.000001))


func validate() -> bool:
	for field: String in ["ground_max_speed", "ground_acceleration", "ground_deceleration",
			"air_max_speed", "air_acceleration", "air_deceleration", "rise_gravity", "fall_gravity",
			"terminal_velocity", "jump_force", "second_jump_force", "wall_slide_speed",
			"wall_jump_horizontal_force", "wall_jump_vertical_force", "wall_probe_distance",
			"floor_snap_distance", "slope_gravity_multiplier"]:
		var value: float = float(get(field))
		if not is_finite(value) or value <= 0.0:
			return false
	for field: String in ["coyote_time", "wall_jump_input_lock_time", "dash_end_lag",
			"respawn_invulnerability"]:
		var value: float = float(get(field))
		if not is_finite(value) or value < 0.0 or value > 10.0:
			return false
	return is_finite(dash_duration) and dash_duration >= STEP and dash_duration <= 2.0 and (
		is_finite(dash_speed) and dash_speed > 0.0 and
		is_finite(dash_momentum_retention) and dash_momentum_retention >= 0.0 and
		dash_momentum_retention <= 1.0 and is_finite(jump_cut_gravity_multiplier) and
		jump_cut_gravity_multiplier >= 1.0 and is_finite(wall_slide_gravity_multiplier) and
		wall_slide_gravity_multiplier > 0.0 and wall_slide_gravity_multiplier <= 1.0 and
		is_finite(wall_normal_max_y) and wall_normal_max_y >= 0.0 and wall_normal_max_y <= 0.3 and
		is_finite(slope_slide_angle_degrees) and slope_slide_angle_degrees >= 5.0 and
		slope_slide_angle_degrees <= 80.0)
