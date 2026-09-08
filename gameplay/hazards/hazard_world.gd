class_name HazardWorld
extends Node2D
## One explicit offline authority per level/station. Owns bounded pool and engagement leases.

const MAX_PLAYERS: int = 2
@export var caps: HazardCapsConfig = preload("res://gameplay/hazards/default_caps.tres")
var players: Dictionary[StringName, PlayerController] = {}
var generations: Dictionary[StringName, int] = {}
var engagements: Dictionary[StringName, Array] = {}
var projectiles: Array[HazardProjectile] = []
var skipped_shots: int = 0
var _generation: int = 0


func _ready() -> void:
	if caps == null or not caps.validate():
		push_error("Invalid hazard caps")
		return
	# Snapshot shared authoring resource; changing caps requires recreating this owner.
	caps = caps.duplicate() as HazardCapsConfig
	for index: int in caps.projectiles_global:
		var projectile := HazardProjectile.new()
		projectile.pool = self
		add_child(projectile)
		projectiles.append(projectile)


func register_player(id: StringName, actor: PlayerController) -> bool:
	if id == &"" or not is_instance_valid(actor) or players.has(id) \
		or players.size() >= MAX_PLAYERS or players.values().has(actor):
		return false
	players[id] = actor
	_generation += 1
	generations[id] = _generation
	engagements[id] = []
	actor.died.connect(retire_target.bind(id))
	actor.relocated.connect(_relocated.bind(id))
	actor.tree_exiting.connect(unregister_player.bind(id))
	return true


func _relocated(_position: Vector2, id: StringName) -> void:
	retire_target(id)


func retire_target(id: StringName) -> void:
	for projectile: HazardProjectile in projectiles:
		if projectile.active and projectile.target_player_id == id:
			projectile.recycle()
	engagements[id] = []
	_generation += 1
	generations[id] = _generation


func unregister_player(id: StringName) -> void:
	retire_target(id)
	var actor: PlayerController = players.get(id)
	if is_instance_valid(actor):
		actor.died.disconnect(retire_target.bind(id))
		actor.relocated.disconnect(_relocated.bind(id))
		actor.tree_exiting.disconnect(unregister_player.bind(id))
	players.erase(id)
	engagements.erase(id)
	generations.erase(id)


func target(id: StringName) -> PlayerController:
	var actor: PlayerController = players.get(id)
	if not is_instance_valid(actor) or not actor.is_inside_tree() or actor.motor == null \
		or actor.start_blocked or actor.motor.machine.locked():
		return null
	return actor


func acquire(id: StringName, turret_id: int) -> bool:
	if target(id) == null:
		return false
	var owners: Array = engagements[id]
	if owners.has(turret_id):
		return true
	if owners.size() >= caps.engaging_turrets_per_target:
		return false
	owners.append(turret_id)
	return true


func release(id: StringName, turret_id: int) -> void:
	if engagements.has(id):
		engagements[id].erase(turret_id)


func active_count(id: StringName = &"") -> int:
	var count: int = 0
	for projectile: HazardProjectile in projectiles:
		if projectile.active and (id == &"" or projectile.target_player_id == id):
			count += 1
	return count


func fire(id: StringName, origin: Vector2, direction: Vector2,
		config: TurretConfig, turret_id: int) -> HazardProjectile:
	if target(id) == null or not origin.is_finite() or not direction.is_finite() \
		or direction.is_zero_approx():
		return null
	if active_count(id) >= caps.projectiles_per_target or active_count() >= caps.projectiles_global:
		skipped_shots += 1
		return null
	for projectile: HazardProjectile in projectiles:
		if not projectile.active:
			projectile.activate(id, origin, direction, config, turret_id)
			return projectile
	return null


func retire_turret(turret_id: int) -> void:
	for id: StringName in engagements:
		release(id, turret_id)
	for projectile: HazardProjectile in projectiles:
		if projectile.active and projectile.source_id == turret_id:
			projectile.recycle()


func _exit_tree() -> void:
	for id: StringName in players.keys():
		unregister_player(id)
