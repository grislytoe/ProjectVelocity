class_name TurretChannel
extends RefCounted
## One barrel / one stable player ID. Lease covers Aim, Telegraph and Fire only.

enum State { DETECTION, LINE_OF_SIGHT, AIM, TELEGRAPH, FIRE, COOLDOWN }
var state: State = State.DETECTION
var target_player_id: StringName
var angle: float = 0.0
var remaining_ticks: int = 0
var shots: int = 0
var skipped: int = 0
var generation: int = -1


func reset(world: HazardWorld, owner_id: int) -> void:
	world.release(target_player_id, owner_id)
	state = State.DETECTION
	remaining_ticks = 0


func step(world: HazardWorld, owner_id: int, origin: Vector2, config: TurretConfig) -> void:
	var current_generation: int = world.generations.get(target_player_id, -1)
	if generation != current_generation:
		reset(world, owner_id)
		generation = current_generation
	var actor: PlayerController = world.target(target_player_id)
	if actor == null:
		reset(world, owner_id)
		return
	if state == State.COOLDOWN:
		remaining_ticks -= 1
		if remaining_ticks <= 0:
			state = State.DETECTION
		return
	var distance: float = origin.distance_to(actor.global_position)
	if distance > config.detection_range:
		reset(world, owner_id)
		return
	if state == State.DETECTION:
		state = State.LINE_OF_SIGHT
		return
	var sight := PhysicsRayQueryParameters2D.create(origin, actor.global_position, 1)
	var clear: bool = world.get_world_2d().direct_space_state.intersect_ray(sight).is_empty()
	if not clear or distance > config.fire_range:
		reset(world, owner_id)
		return
	if state == State.LINE_OF_SIGHT:
		if world.acquire(target_player_id, owner_id):
			state = State.AIM
		return
	# Target retirement can invalidate a lease between ticks.
	if not world.acquire(target_player_id, owner_id):
		reset(world, owner_id)
		return
	if state == State.AIM:
		var desired: float = (config.lead_point(origin, actor.global_position, actor.velocity) - origin).angle()
		angle = rotate_toward(angle, desired, config.aim_turn_speed / 60.0)
		if absf(angle_difference(angle, desired)) <= config.aim_tolerance:
			state = State.TELEGRAPH
			remaining_ticks = maxi(1, PlayerMovementConfig.ticks(config.telegraph_duration))
	elif state == State.TELEGRAPH:
		# Lock warning direction: the shot follows exactly the displayed line.
		remaining_ticks -= 1
		if remaining_ticks <= 0:
			state = State.FIRE
	elif state == State.FIRE:
		if world.fire(target_player_id, origin, Vector2.RIGHT.rotated(angle), config, owner_id) != null:
			shots += 1
		else:
			skipped += 1
		world.release(target_player_id, owner_id)
		state = State.COOLDOWN
		remaining_ticks = maxi(1, PlayerMovementConfig.ticks(maxf(config.cooldown, config.minimum_cooldown)))
