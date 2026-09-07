extends Node2D
## Developer pose sheet: explicit cosmetic previews, no controller or save service.

var previews: Array[PlayerPlaceholder] = []
var body_picker: ColorPickerButton
var accent_picker: ColorPickerButton
var readiness: CheckButton
var profile: PlayerProfileData
var ticks: int = 0


func _ready() -> void:
	profile = PlayerProfileData.create()
	profile.nickname = "Opponent"
	profile.body_color = "44cceeff"
	profile.accent_color = "b6ffdcff"
	label_at(tr("M4_GALLERY"), Vector2(50, 30), 34)
	label_at(tr("M4_GALLERY_HINT"), Vector2(50, 85), 22)
	label_at(tr("M4_BODY_COLOR"), Vector2(50, 135), 20)
	body_picker = ColorPickerButton.new()
	body_picker.position = Vector2(205, 130)
	body_picker.size = Vector2(90, 35)
	body_picker.color = Color.html(profile.body_color)
	body_picker.edit_alpha = false
	body_picker.color_changed.connect(change_palette)
	add_child(body_picker)
	label_at(tr("M4_ACCENT_COLOR"), Vector2(330, 135), 20)
	accent_picker = ColorPickerButton.new()
	accent_picker.position = Vector2(495, 130)
	accent_picker.size = Vector2(90, 35)
	accent_picker.color = Color.html(profile.accent_color)
	accent_picker.edit_alpha = false
	accent_picker.color_changed.connect(change_palette)
	add_child(accent_picker)
	readiness = CheckButton.new()
	readiness.text = tr("M4_READY")
	readiness.position = Vector2(630, 130)
	readiness.button_pressed = true
	add_child(readiness)
	for pose: int in 14:
		var center := Vector2(150 + (pose % 7) * 267, 340 + (pose / 7) * 300)
		label_at(PlayerAnimationMachine.Pose.keys()[pose], center + Vector2(-95, -105), 20)
		for opponent: bool in [false, true]:
			var visual := PlayerPlaceholder.new()
			visual.position = center + Vector2(48 if opponent else -48, 0)
			visual.is_local = not opponent
			visual.apply_profile(profile)
			add_child(visual)
			previews.append(visual)
	label_at(tr("M4_GALLERY_FOOTER"), Vector2(50, 850), 22)


func change_palette(_color: Color) -> void:
	if body_picker == null or accent_picker == null:
		return
	profile.body_color = body_picker.color.to_html(true)
	profile.accent_color = accent_picker.color.to_html(true)
	for visual: PlayerPlaceholder in previews:
		visual.apply_profile(profile)


func _physics_process(_delta: float) -> void:
	ticks += 1
	for index: int in previews.size():
		var pose: PlayerAnimationMachine.Pose = (index / 2) as PlayerAnimationMachine.Pose
		var visual: PlayerPlaceholder = previews[index]
		var frame := PlayerVisualFrame.new()
		frame.velocity.x = 680
		frame.speed_ratio = 1
		frame.jump_ready = readiness.button_pressed
		frame.dash_ready = readiness.button_pressed
		frame.dash_vector = Vector2.RIGHT.rotated((ticks / 60 % 8) * PI / 4)
		visual.present(frame, Vector2.UP if pose == PlayerAnimationMachine.Pose.IDLE else Vector2.ZERO)
		# A pose sheet deliberately scrubs cosmetic time; no gameplay actor exists here.
		visual.animation.enter(pose)
		visual.animation.age_ticks = ticks % 28
		visual.pose_modules()
		visual.queue_redraw()


func label_at(value: String, location: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = location
	label.add_theme_font_size_override("font_size", font_size)
	add_child(label)
