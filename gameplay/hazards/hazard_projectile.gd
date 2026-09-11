class_name HazardProjectile
extends Node2D
## Two swept circles: world blockers and designated target. No homing or transport.

var pool: HazardWorld
var active: bool = false
signal fired
signal returned
signal confirmed_hit(player_id: StringName, generation: int)
var generation: int = 0
var target_player_id: StringName = &""
var source_id: int = 0
var velocity: Vector2 = Vector2.ZERO
var remaining_ticks: int = 0
var radius: float = 0
var _geometry: ShapeCast2D
var _actors: ShapeCast2D


func _ready() -> void:
	top_level = true
	process_physics_priority = 30
	_geometry = _make_cast(1)
	_actors = _make_cast(2)
	recycle()


func _make_cast(mask: int) -> ShapeCast2D:
	var cast := ShapeCast2D.new()
	cast.shape = CircleShape2D.new()
	cast.collision_mask = mask
	cast.enabled = false
	cast.max_results = 32
	cast.margin = 0.001
	add_child(cast)
	return cast


func activate(id: StringName, origin: Vector2, direction: Vector2,
		config: TurretConfig, turret_id: int) -> void:
	generation += 1
	target_player_id = id
	source_id = turret_id
	global_transform = Transform2D(0.0, origin)
	velocity = direction.normalized() * config.projectile_speed
	remaining_ticks = maxi(1, PlayerMovementConfig.ticks(config.projectile_lifetime))
	radius = config.projectile_radius
	(_geometry.shape as CircleShape2D).radius = radius
	(_actors.shape as CircleShape2D).radius = radius
	_geometry.clear_exceptions()
	_actors.clear_exceptions()
	active = true
	# Presentation only: match the designated actor, never alter collision/target authority.
	var actor: PlayerController = pool.target(id)
	self_modulate = Color.WHITE
	if actor != null and is_instance_valid(actor.presentation):
		self_modulate.a = actor.presentation.modulate.a
	visible = true
	set_physics_process(true)
	reset_physics_interpolation()
	queue_redraw()
	fired.emit()


func recycle() -> void:
	if active:
		returned.emit()
	active = false
	visible = false
	self_modulate = Color.WHITE
	target_player_id = &""
	source_id = 0
	velocity = Vector2.ZERO
	remaining_ticks = 0
	radius = 0
	transform = Transform2D.IDENTITY
	if _actors != null:
		_actors.clear_exceptions()
		_actors.target_position = Vector2.ZERO
		_geometry.clear_exceptions()
		_geometry.target_position = Vector2.ZERO
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	var actor: PlayerController = pool.target(target_player_id)
	if actor == null or remaining_ticks <= 0:
		recycle()
		return
	var motion: Vector2 = velocity / PlayerMovementConfig.PHYSICS_HZ
	_geometry.target_position = motion
	_geometry.force_shapecast_update()
	# Limit the target query to motion before the nearest wall, including initial overlap.
	var fraction: float = _geometry.get_closest_collision_safe_fraction()
	_actors.target_position = motion * fraction
	_actors.clear_exceptions()
	_actors.force_shapecast_update()
	# Ignore any other player-layer body, even if not registered with this authority.
	while _actors.is_colliding():
		var other: CollisionObject2D = _actors.get_collider(0) as CollisionObject2D
		if other == actor:
			var hit_id: StringName = target_player_id
			var hit_generation: int = generation
			if actor.die():
				confirmed_hit.emit(hit_id, hit_generation)
				# died can synchronously return every projectile in this target channel.
				recycle()
				return
		if other == null:
			break
		_actors.add_exception(other)
		_actors.force_shapecast_update()
	if _geometry.is_colliding():
		recycle()
		return
	global_position += motion
	remaining_ticks -= 1
	if remaining_ticks == 0:
		recycle()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color("ffcf63"))
