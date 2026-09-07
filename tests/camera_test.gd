extends SceneTree

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func run() -> void:
	var config := CameraConfig.new()
	check(config.valid(), "Default config")
	check(is_equal_approx(config.zoom_for_view(Vector2(1920, 1080), 1.15), 1.105), "Zoom-in excursion reduced by 30 percent")
	check(is_equal_approx(config.zoom_for_view(Vector2(1920, 1080), 0.85), 0.895), "Zoom-out excursion reduced by 30 percent")
	check(is_equal_approx(config.zoom_for_view(Vector2(1920, 1080)), 1.0), "Neutral framing unchanged")
	var invalid: CameraConfig = config.duplicate() as CameraConfig
	invalid.follow_rate = NAN
	check(not invalid.valid(), "Reject invalid smoothing")
	invalid = config.duplicate() as CameraConfig
	invalid.maximum_zoom = 0.1
	check(not invalid.valid(), "Reject reversed zoom range")
	for size: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1440), Vector2(3840, 2160)]:
		for multiplier: float in [0.1, 1.0, 10.0]:
			var ratio: float = 64 * config.zoom_for_view(size, multiplier) / size.y
			check(ratio >= 0.05 and ratio <= 0.07, "Framing at %s, multiplier %s" % [size, multiplier])
	var bounds := CameraBounds.new()
	bounds.rectangle = Rect2(0, 0, 4000, 2400)
	check(bounds.constrain(Vector2(-100, -100), Vector2(1920, 1080)) == Vector2(960, 540), "Left/top whole viewport clamp")
	check(bounds.constrain(Vector2(5000, 5000), Vector2(1920, 1080)) == Vector2(3040, 1860), "Right/bottom whole viewport clamp")
	check(bounds.constrain(Vector2(1, 1), Vector2(8000, 5000)) == Vector2(2000, 1200), "Small map centered without inverted clamp")
	bounds.enabled = false
	check(bounds.constrain(Vector2.ONE, Vector2(8000, 5000)) == Vector2.ONE, "Bounds can be disabled")
	var model := CameraFollowModel.new()
	model.step(Vector2.ZERO, Vector2.ZERO, Vector2(1920, 1080), config)
	check(model.center == config.follow_offset, "Initial follow snaps without origin sweep")
	model.step(Vector2(100, 0), Vector2(680, 0), Vector2(1920, 1080), config)
	check(model.center.x > 0 and model.center.x < 100, "Follow smooths instead of teleporting")
	for tick: int in 240:
		model.step(Vector2(100, 0), Vector2(680, 0), Vector2(1920, 1080), config)
	check(absf(model.look_offset.x - 149.6) < 0.01, "Forward look-ahead scales with velocity")
	for tick: int in 240:
		model.step(Vector2(100, 0), Vector2(-5000, 5000), Vector2(1920, 1080), config)
	check(absf(model.look_offset.x + 180) < 0.01 and absf(model.look_offset.y - 70) < 0.01, "Dash/terminal speed look-ahead bounded")
	for tick: int in 240:
		model.step(Vector2(100, 0), Vector2(1, -1), Vector2(1920, 1080), config)
	check(model.look_offset.length() < 0.01, "Deadzone/stopping recenter look-ahead")
	var zone := CameraZone.new()
	zone.zone_id = "base"
	zone.rectangle = Rect2(0, 0, 100, 100)
	zone.zoom_multiplier = 1.15
	zone.additional_offset = Vector2(50, 20)
	zone.look_ahead_multiplier = 0
	var higher: CameraZone = zone.duplicate() as CameraZone
	higher.zone_id = "priority"
	higher.priority = 1
	higher.lock_enabled = true
	higher.lock_position = Vector2(80, 90)
	model.select_zone(Vector2(50, 50), [zone, higher], 24)
	check(model.active_zone == higher, "Higher-priority zone wins")
	model.step(Vector2(50, 50), Vector2(100, 0), Vector2(1920, 1080), config, null, true)
	check(model.center == higher.lock_position and is_equal_approx(model.zoom_value, 1.105), "Zone lock and zoom")
	model.select_zone(Vector2(110, 50), [zone, higher], 24)
	check(model.active_zone == higher, "Exit hysteresis prevents boundary chatter")
	model.select_zone(Vector2(130, 50), [zone, higher], 24)
	check(model.active_zone == null, "Zone releases beyond exit margin")
	model.select_zone(Vector2(50, 50), [zone], 24)
	model.step(Vector2(50, 50), Vector2(100, 0), Vector2(1920, 1080), config, null, true)
	check(model.center == Vector2(100, 0), "Zone adds offset to normal follow")
	for tick: int in 120:
		model.step(Vector2(50, 50), Vector2(680, 0), Vector2(1920, 1080), config)
	check(model.look_offset.is_zero_approx(), "Zone can suppress look-ahead")
	higher.priority = 0
	model.select_zone(Vector2(50, 50), [higher, zone], 0)
	check(model.active_zone == zone, "Stable ID tie-break independent of array order")
	zone.enabled = false
	model.select_zone(Vector2(50, 50), [zone], 24)
	check(model.active_zone == null, "Disabled zone releases")
	bounds.enabled = true
	model.active_zone = higher
	higher.lock_position = Vector2(-1000, -1000)
	model.step(Vector2.ZERO, Vector2.ZERO, Vector2(1920, 1080), config, bounds, true)
	check(model.center.x + 0.001 >= 1920 / model.zoom_value / 2, "Map bounds override out-of-map lock (float tolerance)")
	model.active_zone = null
	model.step(Vector2(2000, 1000), Vector2.ZERO, Vector2(1920, 1080), config, null, true)
	check(model.center == Vector2(2000, 930) and model.look_offset == Vector2.ZERO, "Teleport resets lag and look-ahead")
	model.active_zone = higher
	model.step(Vector2(2000, 1000), Vector2.ZERO, Vector2(1920, 1080), config)
	check(model.zoom_value > 1 and model.zoom_value < 1.105, "Zone zoom eases on entry")
	model.active_zone = null
	for tick: int in 180:
		model.step(Vector2(2000, 1000), Vector2.ZERO, Vector2(1920, 1080), config)
	check(absf(model.zoom_value - 1) < 0.0001, "Zone exit restores default zoom")
	check(model.center.distance_to(Vector2(2000, 930)) < 0.001, "Zone exit releases lock smoothly")
	var player: PlayerController = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
	player.simulation_enabled = false
	root.add_child(player)
	var camera := LocalPlayerCamera.new()
	root.add_child(camera)
	camera.follow_local(player)
	check(camera.local_target == player and camera.process_physics_priority > player.process_physics_priority, "Explicit local target; runs after controller")
	player.respawn_at(Vector2(500, 300))
	check(camera.model.center == Vector2(500, 230), "Respawn signal resets camera immediately")
	var other := CharacterBody2D.new()
	root.add_child(other)
	other.position = Vector2(9000, 9000)
	camera.update_follow(false)
	check(camera.local_target == player, "Other actors cannot steal camera")
	camera.follow_local(null)
	check(not player.is_connected("relocated", camera._on_relocated), "Unbinding disconnects old target")
	player.free()
	other.free()
	camera._physics_process(1.0 / 60)
	camera.free()
	check(bool(ProjectSettings.get_setting("physics/common/physics_interpolation", false)), "Physics interpolation enabled")
	if failures == 0:
		print("PROJECTVELOCITY_M5_OK (%d checks)" % checks)
	quit(0 if failures == 0 else 1)
