class_name LocalPlayerCamera
extends Camera2D
## One explicit local target. Never searches players, owns input or mutates the target.

@export var config: CameraConfig = preload("res://core/camera/default_camera.tres")
@export var map_bounds: CameraBounds
@export var zones: Array[CameraZone] = []
var model := CameraFollowModel.new()
var local_target: CharacterBody2D
var _last_target: Vector2 = Vector2.ZERO
var _last_view: Vector2 = Vector2.ZERO
var _configured: bool = false


func _init() -> void:
	# Configure before entering the tree, so interpolation never overrides Idle mode.
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON


func _ready() -> void:
	if config == null or not config.valid() or Engine.physics_ticks_per_second != 60 or (
		map_bounds != null and not map_bounds.valid()):
		push_error("Invalid local camera configuration")
		set_physics_process(false)
		enabled = false
		return
	process_physics_priority = 100
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
	position_smoothing_enabled = false
	rotation_smoothing_enabled = false
	ignore_rotation = true
	top_level = true
	_configured = true
	if is_instance_valid(local_target):
		snap_to_target()


func follow_local(player: CharacterBody2D) -> void:
	if is_instance_valid(local_target) and local_target.has_signal("relocated") and (
		local_target.is_connected("relocated", _on_relocated)):
		local_target.disconnect("relocated", _on_relocated)
	local_target = player
	model.initialized = false
	model.active_zone = null
	if is_instance_valid(local_target) and local_target.has_signal("relocated"):
		local_target.connect("relocated", _on_relocated)
	if is_node_ready() and is_instance_valid(local_target):
		snap_to_target()


func _on_relocated(_position: Vector2) -> void:
	snap_to_target()


func snap_to_target() -> void:
	if not _configured or not is_instance_valid(local_target) or not is_inside_tree():
		return
	model.active_zone = null
	update_follow(true)
	reset_physics_interpolation()
	reset_smoothing()
	force_update_scroll()


func _physics_process(_delta: float) -> void:
	if not _configured or not is_instance_valid(local_target):
		return
	var jumped: bool = local_target.global_position.distance_to(_last_target) > config.teleport_distance
	var resized: bool = not _last_view.is_equal_approx(get_viewport_rect().size)
	if jumped or resized:
		snap_to_target()
	else:
		update_follow(false)


func update_follow(snap: bool) -> void:
	_last_target = local_target.global_position
	_last_view = get_viewport_rect().size
	model.select_zone(_last_target, zones, config.zone_exit_margin)
	model.step(_last_target, local_target.velocity, _last_view, config, map_bounds, snap)
	global_position = model.center
	zoom = Vector2.ONE * model.zoom_value
	force_update_scroll()
