class_name LifecyclePlayground
extends Node2D
## Isolated M7 fixture. No application bootstrap or persistence.

var player: PlayerController
var lifecycle: PlayerLifecycle
var barrier: StartBarrier
var tick: int = 0
var hold_ticks: int = 0
var message_ticks: int = 0
var message: Label
var checkpoints: Array[CheckpointTrigger] = []
var finish: FinishTrigger
var hazard: DeathZone


func _ready() -> void:
	process_physics_priority = -100
	var floor_body := StaticBody2D.new()
	floor_body.position = Vector2(700, 620)
	add_box(floor_body, Vector2(2400, 40), Color("294653"))
	player = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.position = Vector2(0, 566)
	var layer := InputLayer.new()
	add_child(layer)
	player.input_layer = layer
	player.input_provider = sample_input
	add_child(player)
	lifecycle = PlayerLifecycle.new()
	add_child(lifecycle)
	lifecycle.bind(player, player.position)
	lifecycle.progress.configure([&"a", &"b"], [&"a", &"b"])
	for index: int in 2:
		var checkpoint := CheckpointTrigger.new()
		checkpoint.checkpoint_id = &"a" if index == 0 else &"b"
		checkpoint.position = Vector2(350 + index * 650, 386)
		var anchor := Marker2D.new()
		anchor.position = Vector2(checkpoint.position.x - 60, 566)
		add_child(anchor)
		checkpoint.respawn_anchor = anchor
		checkpoint.players[player] = lifecycle
		add_box(checkpoint, Vector2(32, 450), Color(0, 0.8, 0.8, 0.15))
		checkpoints.append(checkpoint)
	hazard = preload("res://gameplay/race/death_zone.tscn").instantiate() as DeathZone
	hazard.position = Vector2(680, 590)
	add_child(hazard)
	finish = FinishTrigger.new()
	finish.position = Vector2(1350, 555)
	finish.players[player] = lifecycle
	add_box(finish, Vector2(35, 90), Color(0.8, 0.9, 0.3, 0.8))
	barrier = StartBarrier.new()
	add_child(barrier)
	var camera := LocalPlayerCamera.new()
	add_child(camera)
	camera.follow_local(player)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var column := VBoxContainer.new()
	column.position = Vector2(24, 24)
	canvas.add_child(column)
	var help := Label.new()
	help.text = tr("M7_HINT")
	help.add_theme_font_size_override("font_size", 23)
	column.add_child(help)
	message = Label.new()
	message.add_theme_font_size_override("font_size", 26)
	column.add_child(message)
	lifecycle.notification.connect(show_message)
	reset_run()


func add_box(body: CollisionObject2D, size: Vector2, color: Color) -> void:
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
	add_child(body)


func reset_run() -> void:
	lifecycle.progress.reached.clear()
	lifecycle.respawn_position = lifecycle.start_position
	player.respawn_at(lifecycle.start_position)
	for checkpoint: CheckpointTrigger in checkpoints:
		checkpoint.activated_players.clear()
		checkpoint.local_active = false
		checkpoint.queue_redraw()
	barrier.actors.clear()
	barrier.arm([player], [&"local"])
	barrier.gate.set_ready(&"local", true)
	barrier.gate.schedule(tick + 180, tick)
	show_message("M7_START")


func sample_input() -> InputFrame:
	var frame: InputFrame = player.input_layer.sample()
	hold_ticks = mini(hold_ticks + 1, 61) if frame.restart_held else 0
	if hold_ticks == 60:
		reset_run()
		return InputFrame.new()
	return frame


func _physics_process(_delta: float) -> void:
	tick += 1
	if barrier.advance(tick):
		show_message("M7_GO")
	message_ticks = maxi(0, message_ticks - 1)
	if message_ticks == 0:
		message.text = ""


func show_message(key: String) -> void:
	message.text = tr(key)
	message_ticks = 150


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F6:
			player.die(true)
		elif event.physical_keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://dev_tools/test_playground.tscn")
