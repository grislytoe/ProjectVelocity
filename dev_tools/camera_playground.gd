extends "res://dev_tools/player_playground.gd"
## Developer-only bounds/zone fixture. All zones use absolute map coordinates.


func _ready() -> void:
	super._ready()
	var ramp := CameraZone.new()
	ramp.zone_id = "ramp_close"
	ramp.rectangle = Rect2(1350, -600, 600, 1500)
	ramp.zoom_multiplier = 1.15
	ramp.additional_offset = Vector2(80, -30)
	ramp.look_ahead_multiplier = 0.5
	var locked := CameraZone.new()
	locked.zone_id = "locked_platform"
	locked.priority = 10
	locked.rectangle = Rect2(2300, -600, 800, 1600)
	locked.lock_enabled = true
	locked.lock_position = Vector2(2300, 300)
	locked.zoom_multiplier = 0.85
	camera.zones = [ramp, locked]
	for zone: CameraZone in camera.zones:
		var visual := Polygon2D.new()
		var rect: Rect2 = zone.rectangle
		visual.polygon = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
		visual.color = Color(0.2, 0.6, 0.8, 0.06)
		visual.z_index = -1
		add_child(visual)
	var positions: Array[Vector2] = [Vector2(150, 500), Vector2(1450, 450), Vector2(2400, 700)]
	var keys: Array[String] = ["M5_START", "M5_RAMP", "M5_LOCK"]
	for index: int in 3:
		var button := Button.new()
		button.text = tr(keys[index])
		button.position = Vector2(28 + index * 270, 145)
		button.size = Vector2(250, 45)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(player.respawn_at.bind(positions[index]))
		hud.get_parent().add_child(button)


func _process(delta: float) -> void:
	super._process(delta)
	var zone_id: String = camera.model.active_zone.zone_id if camera.model.active_zone != null else "default"
	hud.text += "\nM5 | zone=%s | zoom=%.2f" % [zone_id, camera.zoom.x]
