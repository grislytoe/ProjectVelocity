class_name RobotPreview
extends Control
## The same modular M4 robot and appearance pipeline as gameplay, with no physics.

var robot: PlayerPlaceholder
var profile: Dictionary

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(240, 260)
	robot = PlayerPlaceholder.new()
	robot.local_indicator = false
	add_child(robot)
	resized.connect(_layout)
	_layout()
	update_profile(profile)

func _layout() -> void:
	robot.position = Vector2(size.x * 0.5, size.y * 0.48)
	robot.scale = Vector2.ONE * minf(size.y / 90.0, 5.0)
	queue_redraw()

func update_profile(value: Dictionary) -> void:
	profile = value
	if is_instance_valid(robot):
		robot.apply_profile(PlayerProfileData.from_dictionary(value))

func _draw() -> void:
	for x: int in range(0, int(size.x), 40):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color("1b303b"))
	for y: int in range(0, int(size.y), 40):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("1b303b"))
	draw_line(Vector2(size.x * 0.2, size.y * 0.84), Vector2(size.x * 0.8, size.y * 0.84), Color("73e7d2"), 2)
