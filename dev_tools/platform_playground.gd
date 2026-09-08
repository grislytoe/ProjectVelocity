class_name PlatformPlayground
extends RefCounted
## M8 station composition; each module is a reusable gameplay scene.


static func populate(parent: Node2D, station_id: String) -> void:
	var scene: PackedScene
	match station_id:
		"ONE_WAY": scene = preload("res://gameplay/platforms/one_way_platform.tscn")
		"MOVING": scene = preload("res://gameplay/platforms/moving_platform.tscn")
		"BREAKABLE": scene = preload("res://gameplay/platforms/breakable_platform.tscn")
		"JUMP_PAD": scene = preload("res://gameplay/platforms/jump_pad.tscn")
		_: return
	var platform := scene.instantiate() as Node2D
	platform.name = "Module"
	platform.position = Vector2(420, 400)
	if platform is MovingPlatform:
		var tuning := MovingPlatformConfig.new()
		tuning.color = Color("4d99df")
		tuning.route = PackedVector2Array([Vector2.ZERO, Vector2(220, -180), Vector2(480, 0)])
		tuning.waits = PackedFloat32Array([0.5, 0.5, 0.5])
		platform.config = tuning
	parent.add_child(platform)
	if station_id == "JUMP_PAD":
		var angled := scene.instantiate() as JumpPad
		angled.position = Vector2(1050, 320)
		angled.config = JumpPadConfig.new()
		angled.config.color = Color("bd74df")
		angled.config.direction = Vector2(1, -1)
		angled.config.force = 1350
		parent.add_child(angled)
