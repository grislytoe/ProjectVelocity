extends SceneTree
## Real CharacterBody2D replay. Input is indexed by physics tick, never render frame.

var player: PlayerController
var layer: InputLayer
var tick: int = 0
var checks: int = 0
var failures: int = 0
var trace: PackedStringArray = []
var slope_start: Vector2
var seen: Dictionary = {}


func _initialize() -> void:
	setup.call_deferred()


func setup() -> void:
	box(Vector2(500, 650), Vector2(2000, 100))
	box(Vector2(1000, 200), Vector2(40, 800))
	polygon(PackedVector2Array([Vector2(3000, 600), Vector2(3600, 300), Vector2(3600, 800), Vector2(3000, 800)]))
	polygon(PackedVector2Array([Vector2(4000, 600), Vector2(4300, 0), Vector2(4300, 800), Vector2(4000, 800)]))
	layer = InputLayer.new()
	layer.watch_hardware = false
	root.add_child(layer)
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	if OS.get_cmdline_user_args().has("--without-presentation"):
		player.get_node("Presentation").free()
	player.position = Vector2(100, 500)
	player.input_provider = provide
	player.input_layer = layer
	root.add_child(player)


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)


func provide() -> InputFrame:
	trace.append("%d:%.4f:%.4f:%.4f:%.4f:%d" % [tick, player.position.x, player.position.y,
		player.velocity.x, player.velocity.y, player.motor.machine.current])
	seen[player.motor.machine.current] = true
	var frame := InputFrame.new()
	var phase: int = tick / 120
	var local: int = tick % 120
	if tick == 120:
		check(seen.has(PlayerStateMachine.State.JUMP), "real body jump")
		check(seen.has(PlayerStateMachine.State.DASH), "real body dash")
		player.respawn_at(Vector2(963.9, 0))
	elif tick == 240:
		check(player.motor.machine.current == PlayerStateMachine.State.WALL_SLIDE, "real wall slide without pushing")
		check(player.position.y > 100 and player.position.y < 250, "controlled wall descent")
		player.respawn_at(Vector2(963.9, 0))
	elif tick == 360:
		check(player.position.x < 900, "real wall jump separates from wall")
		check(seen.has(PlayerStateMachine.State.WALL_JUMP), "real wall jump state")
		player.respawn_at(Vector2(3200, 400))
	elif tick == 480:
		check(player.position.x > slope_start.x + 100 and player.position.y < slope_start.y - 40, "climb walkable slope")
		check(player.is_on_floor(), "walkable slope retains floor")
		player.respawn_at(Vector2(4150, 180))
	elif tick == 600:
		check(player.position.x < slope_start.x - 20, "steep slope slides downhill")
		check(not player.is_on_floor(), "steep slope is not floor")
		player.respawn_at(Vector2(940, 200))
	elif tick == 720:
		check(player.position.x < 965, "dash cannot tunnel through wall")
		check(player.die(true), "death accepted")
		check(player.velocity == Vector2.ZERO, "death stops body")
		player.respawn_at(Vector2(100, 500))
		check(not player.die(), "respawn invulnerability")
		player.finish_run()
		check(player.motor.machine.current == PlayerStateMachine.State.FINISH, "finish API")
		print("M3_REPLAY_HASH=" + "\n".join(trace).sha256_text())
		if failures == 0:
			print("PROJECTVELOCITY_M3_PHYSICS_OK (%d checks; 720 ticks)" % checks)
		quit(0 if failures == 0 else 1)
	if phase == 0:
		frame.movement.x = 1 if local < 25 else 0
		frame.jump_pressed = local in [30, 45]
		frame.jump_held = local >= 30 and local < 55
		frame.dash_pressed = local == 65
		frame.dash_direction = Vector2.RIGHT
		if local == 25:
			check(player.is_on_floor(), "floor landing")
		if local == 46:
			check(not player.motor.double_jump_available, "real double jump consumed")
	elif phase == 2:
		frame.jump_pressed = local == 15
		frame.jump_held = local >= 15 and local < 40
	elif phase == 3:
		if local == 60:
			slope_start = player.position
			check(player.is_on_floor(), "rest on shallow slope")
		frame.movement.x = 0.35 if local >= 60 else 0
	elif phase == 4 and local == 30:
		slope_start = player.position
	elif phase == 5:
		frame.dash_pressed = local == 5
		frame.dash_direction = Vector2.RIGHT
		if local == 5:
			layer._selected_dash = Vector2.RIGHT
		if local == 6:
			check(layer._selected_dash == Vector2.ZERO, "successful dash clears M2 selection")
		if local == 30:
			check(player.motor.dash_available and player.motor.double_jump_available, "collision refreshes abilities")
	tick += 1
	return frame


func box(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var shape := RectangleShape2D.new()
	shape.size = size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	body.add_child(collider)
	root.add_child(body)


func polygon(points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	var collider := CollisionPolygon2D.new()
	collider.polygon = points
	body.add_child(collider)
	root.add_child(body)
