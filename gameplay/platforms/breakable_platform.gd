class_name BreakablePlatform
extends StaticBody2D
## Standing contact arms once. Restore waits until the entire volume is unoccupied.

enum State { SOLID, ARMED, ABSENT }
@export var config: BreakablePlatformConfig = preload("res://gameplay/platforms/default_breakable.tres")
var state: State = State.SOLID
var remaining_ticks: int = 0
var surface: CollisionPolygon2D
var _clearance := PhysicsShapeQueryParameters2D.new()


func _ready() -> void:
	process_physics_priority = -50
	add_to_group("unsafe_respawn_support")
	if config == null or not config.validate():
		push_error("Invalid breakable platform config")
		set_physics_process(false)
		return
	surface = PlatformGeometry.build(self, config)
	var shape := ConvexPolygonShape2D.new()
	shape.points = config.polygon
	_clearance.shape = shape
	_clearance.collision_mask = 2
	_clearance.exclude = [get_rid()]


func on_player_contact(player: PlayerController, normal: Vector2) -> void:
	if state != State.SOLID or player.motor.machine.locked() or normal.dot(Vector2.UP) < 0.7:
		return
	state = State.ARMED
	remaining_ticks = maxi(1, PlayerMovementConfig.ticks(config.activation_delay))
	(get_node("Surface") as Polygon2D).color = Color("edaa42")


func _physics_process(_delta: float) -> void:
	if state == State.SOLID:
		return
	remaining_ticks = maxi(0, remaining_ticks - 1)
	if remaining_ticks > 0:
		return
	if state == State.ARMED:
		state = State.ABSENT
		surface.disabled = true
		(get_node("Surface") as Polygon2D).modulate.a = 0.15
		remaining_ticks = maxi(1, PlayerMovementConfig.ticks(config.restore_delay))
	elif config.restores:
		_clearance.transform = global_transform
		if not get_world_2d().direct_space_state.intersect_shape(_clearance, 1).is_empty():
			return
		state = State.SOLID
		surface.disabled = false
		(get_node("Surface") as Polygon2D).modulate.a = 1.0
		(get_node("Surface") as Polygon2D).color = config.color
