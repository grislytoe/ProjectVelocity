class_name SoloCourse
extends Node2D
## Owns runtime actors; MapAssembly owns geometry. Lifecycle remains progress authority.

var player: PlayerController
var lifecycle: PlayerLifecycle
var world: HazardWorld
var checkpoints: Array[CheckpointTrigger] = []
var finish: FinishTrigger
var input_layer: InputLayer
var definition: MapDefinition = MapCatalog.training()
var assembly: MapAssembly
var diagnostics := MapDiagnostics.new()

func _ready() -> void:
	diagnostics = MapValidator.inspect(definition)
	if not diagnostics.valid():
		return
	assembly = MapAssembly.new()
	assembly.assemble(definition)
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.position = assembly.point_position(definition.start, true)
	player.input_layer = input_layer
	player.start_blocked = true
	add_child(player)
	lifecycle = PlayerLifecycle.new()
	add_child(lifecycle)
	lifecycle.bind(player, player.position)
	lifecycle.progress.configure(definition.checkpoint_ids, definition.mandatory_ids, definition.strict_order)
	for point: MapPoint in definition.checkpoints:
		var trigger := CheckpointTrigger.new()
		trigger.checkpoint_id = point.point_id
		var anchor := Marker2D.new()
		anchor.position = assembly.point_position(point, true)
		add_child(anchor)
		trigger.respawn_anchor = anchor
		trigger.players[player] = lifecycle
		box(self, trigger, assembly.point_position(point), point.trigger_size, Color(0, 0.8, 0.8, 0.12))
		checkpoints.append(trigger)
	finish = FinishTrigger.new()
	finish.players[player] = lifecycle
	box(self, finish, assembly.point_position(definition.finish),
		definition.finish.trigger_size, Color("adcc43"))
	world = HazardWorld.new()
	add_child(world)
	world.register_player(&"local", player)
	assembly.bind_hazards(world)
	add_child(assembly)
	var pit := DeathZone.new()
	box(self, pit, definition.death_bounds.get_center(), definition.death_bounds.size, Color("a33d53"))
	var camera := LocalPlayerCamera.new()
	add_child(camera)
	camera.follow_local(player)

func validate_respawns() -> bool:
	if not diagnostics.valid():
		return false
	var points: Array[MapPoint] = [definition.start]
	points.append_array(definition.checkpoints)
	for point: MapPoint in points:
		if not RespawnSafety.valid(player, to_global(assembly.point_position(point, true))):
			diagnostics.add("respawn", str(point.point_id), "Capsule clearance, static support or fatal exclusion failed")
	return diagnostics.valid()

func box(parent: Node, body: CollisionObject2D, position_value: Vector2,
		size: Vector2, color: Color) -> void:
	body.position = position_value
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([-size / 2, Vector2(size.x, -size.y) / 2,
		size / 2, Vector2(-size.x, size.y) / 2])
	visual.color = color
	body.add_child(visual)
	parent.add_child(body)
