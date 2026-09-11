class_name NetworkCourse
extends SoloCourse
## Reuses validated M13/M14 assembly and M7/M9 primitives, without SoloTrial or records.

var host: bool = true
var actors: Array[PlayerController] = []
var lives: Array[PlayerLifecycle] = []
var dynamics: Array[Node2D] = []
var dynamic_types: Array[int] = []
var remote: PlayerController
var fatal_volumes: Array[DeathZone] = []

func _ready() -> void:
	super._ready()
	if not diagnostics.valid():
		return
	actors.append(player)
	lives.append(lifecycle)
	var guest := preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	guest.position = player.position
	guest.start_blocked = true
	add_child(guest)
	actors.append(guest)
	var life := PlayerLifecycle.new()
	add_child(life)
	life.bind(guest, guest.position)
	life.progress.configure(definition.checkpoint_ids, definition.mandatory_ids, definition.strict_order)
	lives.append(life)
	world.register_player(&"absent", guest)
	for checkpoint: CheckpointTrigger in checkpoints:
		checkpoint.players[guest] = life
	finish.players[guest] = life
	remote = guest if host else player
	for i: int in 2:
		actors[i].simulation_enabled = false
		actors[i].gameplay_authority = host
		actors[i].presentation.is_local = (i == 0) == host
		lives[i].set_physics_process(false)
	if not host:
		remote.collision_layer = 0
		remote.collision_mask = 0
	for node: Node in find_children("*", "", true, false):
		var type: int = dynamic_type(node)
		if type >= 0:
			dynamics.append(node as Node2D)
			dynamic_types.append(type)
			node.set_physics_process(false)
		if node is DeathZone:
			node.set_physics_process(false)
			if not node is CycleHazard and not node is Saw:
				fatal_volumes.append(node as DeathZone)
		if not host and node is Area2D:
			(node as Area2D).collision_mask = 0
		if node is LocalPlayerCamera:
			(node as LocalPlayerCamera).follow_local(actors[0 if host else 1])

static func dynamic_type(node: Node) -> int:
	if node is MovingPlatform: return 0
	if node is BreakablePlatform: return 1
	if node is CycleHazard: return 2
	if node is Saw: return 3
	if node is Turret: return 4
	if node is HazardProjectile: return 5
	return -1

func advance_world(before_players: bool) -> void:
	for i: int in dynamics.size():
		var type: int = dynamic_types[i]
		if (type <= 1) == before_players:
			var node: Node2D = dynamics[i]
			if type != 5 or (node as HazardProjectile).active:
				node._physics_process(1.0 / 60.0)
	if not before_players:
		# The course's pit is not part of the dynamic registry.
		for volume: DeathZone in fatal_volumes:
			volume._physics_process(1.0 / 60.0)
		for life: PlayerLifecycle in lives:
			life.advance()
	# Projectile activate/recycle toggles automatic processing; keep session as sole scheduler.
	for projectile: HazardProjectile in world.projectiles:
		projectile.set_physics_process(false)

func capture_dynamics() -> Array:
	var result: Array = []
	for i: int in dynamics.size():
		var node: Node2D = dynamics[i]
		var row: Array = [i, dynamic_types[i], node.position.x, node.position.y, 0, 0, 0, 0, 0, 0]
		match dynamic_types[i]:
			0, 3:
				row[4] = node.elapsed_ticks
			1:
				row[4] = node.state
				row[5] = node.remaining_ticks
			2:
				row[4] = node.state
				row[5] = node.elapsed_ticks
			4:
				row[4] = node.channels[0].angle
				row[5] = node.channels[0].state
				row[6] = node.channels[1].angle
				row[7] = node.channels[1].state
			5:
				row[4] = 1 if node.active else 0
				row[5] = 1 if node.target_player_id == &"local" else 2
				row[6] = node.velocity.x
				row[7] = node.velocity.y
				row[8] = node.radius
				row[9] = node.remaining_ticks
		result.append(row)
	return result

func valid_dynamics(rows: Array) -> bool:
	if rows.size() != dynamics.size():
		return false
	for i: int in rows.size():
		var row: Array = rows[i]
		if int(row[0]) != i or int(row[1]) != dynamic_types[i]:
			return false
		match dynamic_types[i]:
			0, 3:
				if not NetPacket.integer(row[4], 0, 10000000): return false
			1, 2:
				if not NetPacket.integer(row[4], 0, 2): return false
			4:
				if not NetPacket.integer(row[5], 0, 5) or not NetPacket.integer(row[7], 0, 5): return false
			5:
				if not NetPacket.integer(row[4], 0, 1) or not NetPacket.integer(row[5], 1, 2) \
					or row[8] < 0 or row[8] > 128: return false
	return true

func apply_dynamics(rows: Array, extra_ticks: int = 0) -> void:
	for i: int in rows.size():
		var row: Array = rows[i]
		var node: Node2D = dynamics[i]
		node.position = Vector2(row[2], row[3])
		match dynamic_types[i]:
			0:
				node.position = node._origin + node.route.sample(int(row[4]) + extra_ticks)
			3:
				if node.route != null:
					node.position = node._origin + node.route.sample(int(row[4]) + extra_ticks)
			1:
				node.state = int(row[4])
				node.surface.disabled = node.state == BreakablePlatform.State.ABSENT
				node.get_node("Surface").modulate.a = 0.15 if node.surface.disabled else 1.0
				node.get_node("Surface").color = Color("edaa42") if node.state == 1 else node.config.color
			2:
				node.state = int(row[4])
				node.lethal = node.state == CycleHazard.State.ACTIVE
				node.queue_redraw()
			4:
				node.channels[0].angle = row[4]
				node.channels[0].state = int(row[5])
				node.channels[1].angle = row[6]
				node.channels[1].state = int(row[7])
				node.queue_redraw()
			5:
				node.visible = row[4] == 1
				node.position += Vector2(row[6], row[7]) * mini(extra_ticks, 3) / 60.0
				node.radius = row[8]
				node.self_modulate.a = 1.0 if int(row[5]) == (1 if host else 2) else 0.3
				node.queue_redraw()
