class_name Turret
extends Node2D

@export var config: TurretConfig = preload("res://gameplay/hazards/default_turret.tres")
## Empty slot inherits common tuning; each barrel can author an independent override.
@export var barrel_one_config: TurretConfig
@export var barrel_two_config: TurretConfig
var authority: HazardWorld
var channels: Array[TurretChannel] = []


func bind(world: HazardWorld, ids: Array[StringName]) -> bool:
	if ids.size() != 2 or ids[0] == ids[1] or is_inside_tree() or not channels.is_empty():
		return false
	authority = world
	for id: StringName in ids:
		var channel := TurretChannel.new()
		channel.target_player_id = id
		channels.append(channel)
	return true


func tuning(index: int) -> TurretConfig:
	var override: TurretConfig = barrel_one_config if index == 0 else barrel_two_config
	return config if override == null else override


func _ready() -> void:
	process_physics_priority = 20
	if not is_instance_valid(authority) or channels.size() != 2 or config == null or not config.validate() \
		or not tuning(0).validate() or not tuning(1).validate():
		push_error("Turret requires authority, two independent channel IDs and valid configs")
		hide()
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(authority):
		set_physics_process(false)
		return
	for index: int in 2:
		channels[index].step(authority, get_instance_id(), to_global(config.barrel_offsets[index]), tuning(index))
	queue_redraw()


func _exit_tree() -> void:
	if is_instance_valid(authority):
		authority.retire_turret(get_instance_id())
	channels.clear()


func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(-30, 18), Vector2(-25, -16),
		Vector2(-14, -28), Vector2(14, -28), Vector2(25, -16), Vector2(30, 18),
		Vector2(18, 28), Vector2(-18, 28)]), ArtPalette.STEEL_DARK)
	draw_arc(Vector2.ZERO, 28, 0, TAU, 20, ArtPalette.TEXT_MUTED, 2, true)
	draw_circle(Vector2.ZERO, 9, ArtPalette.BACKGROUND)
	for index: int in channels.size():
		var channel: TurretChannel = channels[index]
		var origin: Vector2 = config.barrel_offsets[index]
		var direction := Vector2.RIGHT.rotated(channel.angle - global_rotation)
		var color := Color("58cfea") if index == 0 else Color("c08bff")
		draw_circle(origin, 7, ArtPalette.BACKGROUND)
		draw_line(origin, origin + direction * 43, ArtPalette.STEEL, 12, true)
		draw_line(origin, origin + direction * 43, color, 4, true)
		draw_line(origin + direction * 39, origin + direction * 48, color, 8, true)
		if channel.state in [TurretChannel.State.TELEGRAPH, TurretChannel.State.FIRE]:
			var telegraph := color
			telegraph.a = 0.62
			draw_dashed_line(origin + direction * 50, origin + direction * tuning(index).fire_range,
				telegraph, 2, 14, true)
			draw_circle(origin + direction * 50, 4, ArtPalette.WARNING, false, 2, true)
