class_name SoloCourse
extends Node2D
## Short playable module demonstration. Each retry reconstructs this entire owned subtree.

var player: PlayerController
var lifecycle: PlayerLifecycle
var world: HazardWorld
var checkpoints: Array[CheckpointTrigger] = []
var finish: FinishTrigger
var input_layer: InputLayer
var definition := TrialMapDefinition.new()

func _ready() -> void:
	var sections: Array[Node2D] = []
	for index: int in 3:
		var section := Node2D.new()
		section.name = "Section%d" % (index + 1)
		add_child(section)
		sections.append(section)
		box(section, StaticBody2D.new(), Vector2(700 + index * 1400, 620),
			Vector2(1400, 40), Color("294653"))
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.position = Vector2(100, 566)
	player.input_layer = input_layer
	add_child(player)
	lifecycle = PlayerLifecycle.new()
	add_child(lifecycle)
	lifecycle.bind(player, player.position)
	lifecycle.progress.configure(definition.checkpoint_ids, definition.checkpoint_ids)
	for index: int in 2:
		var trigger := CheckpointTrigger.new()
		trigger.checkpoint_id = definition.checkpoint_ids[index]
		var anchor := Marker2D.new()
		anchor.position = Vector2(1350 + index * 1400, 566)
		add_child(anchor)
		trigger.respawn_anchor = anchor
		trigger.players[player] = lifecycle
		box(sections[index], trigger, Vector2(1400 + index * 1400, 386),
			Vector2(32, 450), Color(0, 0.8, 0.8, 0.12))
		checkpoints.append(trigger)
	finish = FinishTrigger.new()
	finish.players[player] = lifecycle
	box(sections[2], finish, Vector2(4020, 386), Vector2(45, 450), Color("adcc43"))
	var spikes := preload("res://gameplay/hazards/spikes.tscn").instantiate() as Spikes
	spikes.position = Vector2(760, 588)
	sections[0].add_child(spikes)
	var moving := preload("res://gameplay/platforms/moving_platform.tscn").instantiate() as MovingPlatform
	moving.position = Vector2(1800, 460)
	sections[1].add_child(moving)
	var one_way: Node2D = preload("res://gameplay/platforms/one_way_platform.tscn").instantiate()
	one_way.position = Vector2(2150, 430)
	sections[1].add_child(one_way)
	var temporary: Node2D = preload("res://gameplay/platforms/breakable_platform.tscn").instantiate()
	temporary.position = Vector2(2500, 470)
	sections[1].add_child(temporary)
	world = HazardWorld.new()
	add_child(world)
	world.register_player(&"local", player)
	var turret := preload("res://gameplay/hazards/turret.tscn").instantiate() as Turret
	turret.position = Vector2(3550, 400)
	turret.bind(world, [&"local", &"absent"])
	sections[2].add_child(turret)
	var pit := DeathZone.new()
	box(self, pit, Vector2(2100, 1100), Vector2(12000, 100), Color("a33d53"))
	var camera := LocalPlayerCamera.new()
	add_child(camera)
	camera.follow_local(player)

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
