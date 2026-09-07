class_name CameraConfig
extends Resource
## Camera tuning only; reference framing is 64 / 1080 = 5.93% of screen height.

@export var base_zoom: float = 1.0
@export var minimum_zoom: float = 0.85
@export var maximum_zoom: float = 1.15
@export_range(0.0, 1.0) var zoom_variation_strength: float = 0.7
@export var reference_height: float = 1080.0
@export var follow_rate: float = 9.0
@export var look_ahead_rate: float = 7.0
@export var zoom_rate: float = 6.0
@export var follow_offset := Vector2(0, -70)
@export var look_ahead_seconds: float = 0.22
@export var look_ahead_limit := Vector2(180, 70)
@export var velocity_deadzone: float = 20.0
@export var zone_exit_margin: float = 24.0
@export var teleport_distance: float = 1200.0


func valid() -> bool:
	for field: String in ["base_zoom", "minimum_zoom", "maximum_zoom", "reference_height",
		"follow_rate", "look_ahead_rate", "zoom_rate", "teleport_distance"]:
		if not is_finite(float(get(field))) or float(get(field)) <= 0:
			return false
	for field: String in ["look_ahead_seconds", "velocity_deadzone", "zone_exit_margin"]:
		if not is_finite(float(get(field))) or float(get(field)) < 0:
			return false
	return is_finite(zoom_variation_strength) and zoom_variation_strength >= 0 and zoom_variation_strength <= 1 and (
		minimum_zoom <= base_zoom and base_zoom <= maximum_zoom and follow_offset.is_finite()) and (
		look_ahead_limit.is_finite() and look_ahead_limit.x >= 0 and look_ahead_limit.y >= 0)


func zoom_for_view(view_size: Vector2, multiplier: float = 1.0) -> float:
	var requested_zoom: float = clampf(base_zoom * multiplier, minimum_zoom, maximum_zoom)
	return lerpf(base_zoom, requested_zoom, zoom_variation_strength) * view_size.y / reference_height
