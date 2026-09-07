class_name CameraFollowModel
extends RefCounted
## Fixed-step camera state. Reads position/velocity values and cannot steer the player.

var center: Vector2 = Vector2.ZERO
var zoom_value: float = 1.0
var look_offset: Vector2 = Vector2.ZERO
var initialized: bool = false
var active_zone: CameraZone


func select_zone(point: Vector2, zones: Array[CameraZone], exit_margin: float) -> void:
	var selected: CameraZone
	for zone: CameraZone in zones:
		if zone == null or not zone.valid() or not zone.contains(point, exit_margin if zone == active_zone else 0.0):
			continue
		if selected == null or zone.priority > selected.priority or (
			zone.priority == selected.priority and zone.zone_id < selected.zone_id):
			selected = zone
	active_zone = selected


func step(point: Vector2, velocity: Vector2, view_size: Vector2, config: CameraConfig,
		bounds: CameraBounds = null, snap: bool = false) -> void:
	var zone_zoom: float = active_zone.zoom_multiplier if active_zone != null else 1.0
	var look_multiplier: float = active_zone.look_ahead_multiplier if active_zone != null else 1.0
	var offset: Vector2 = config.follow_offset
	if active_zone != null:
		offset += active_zone.additional_offset
	var target_look: Vector2 = velocity * config.look_ahead_seconds * look_multiplier
	for axis: int in 2:
		if absf(velocity[axis]) < config.velocity_deadzone:
			target_look[axis] = 0
		target_look[axis] = clampf(target_look[axis], -config.look_ahead_limit[axis], config.look_ahead_limit[axis])
	var target_zoom: float = config.zoom_for_view(view_size, zone_zoom)
	if snap or not initialized:
		look_offset = Vector2.ZERO
		zoom_value = target_zoom
	else:
		look_offset = look_offset.lerp(target_look, 1.0 - exp(-config.look_ahead_rate / 60.0))
		zoom_value = lerpf(zoom_value, target_zoom, 1.0 - exp(-config.zoom_rate / 60.0))
	var desired: Vector2 = point + offset + look_offset
	if active_zone != null and active_zone.lock_enabled:
		desired = active_zone.lock_position
	if bounds != null:
		desired = bounds.constrain(desired, view_size / zoom_value)
	center = desired if snap or not initialized else center.lerp(desired, 1.0 - exp(-config.follow_rate / 60.0))
	if bounds != null:
		center = bounds.constrain(center, view_size / zoom_value)
	initialized = true
