extends SceneTree
## Value-level transitions plus actual modular nodes. No production saves.

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
	var expected: Array[int] = [PlayerAnimationMachine.Pose.IDLE, PlayerAnimationMachine.Pose.RUN,
		PlayerAnimationMachine.Pose.JUMP, PlayerAnimationMachine.Pose.FALL,
		PlayerAnimationMachine.Pose.WALL_SLIDE, PlayerAnimationMachine.Pose.WALL_JUMP,
		PlayerAnimationMachine.Pose.DASH, PlayerAnimationMachine.Pose.DEATH,
		PlayerAnimationMachine.Pose.RESPAWN, PlayerAnimationMachine.Pose.FINISH_VICTORY]
	for state: int in expected.size():
		var machine := PlayerAnimationMachine.new()
		var frame := PlayerVisualFrame.new()
		frame.state = state as PlayerStateMachine.State
		machine.advance(frame)
		check(machine.current == expected[state], "Explicit state mapping %d" % state)
	var motor := PlayerMotor.new(PlayerMovementConfig.new())
	motor.velocity = Vector2(321, -456)
	var snapshot: PlayerVisualFrame = PlayerVisualFrame.from_motor(motor)
	snapshot.velocity = Vector2.ZERO
	snapshot.jump_ready = false
	check(motor.velocity == Vector2(321, -456) and motor.double_jump_available, "Snapshot does not expose authority")
	var visual := PlayerPlaceholder.new()
	root.add_child(visual)
	var profile: PlayerProfileData = PlayerProfileData.create()
	profile.nickname = "Тест Player"
	profile.body_color = "ee663300"
	profile.accent_color = "55ff88aa"
	profile.cosmetic_slots.head = "future-head"
	check(visual.apply_profile(profile), "Validated profile applied")
	check(visual.appearance.body_color == Color("ee6633"), "Body RGB preserved; opacity not controlled by profile alpha")
	check(visual.appearance.accent_color == Color("55ff88"), "Accent RGB preserved")
	profile.cosmetic_slots.head = "changed"
	check(visual.appearance.slots.head == "future-head", "Cosmetic slot values copied")
	check(visual.parts.size() == 7 and not visual.parts.hat.visible, "Modular base and future hat attachment")
	check(visual.modulate == Color.WHITE and not visual.nickname_label.visible, "Local opaque; own nickname hidden")
	check(visual.parts.head.outline_width > 0, "Local contrast outline")
	var frame := PlayerVisualFrame.new()
	visual.present(frame, Vector2.UP)
	check(visual.selected_direction == Vector2.UP, "Local indicator")
	visual.is_local = false
	visual.present(frame, Vector2.UP)
	check(visual.selected_direction == Vector2.ZERO, "Remote indicator never retained")
	check(is_equal_approx(visual.modulate.a, 0.3), "Opponent alpha applied once to common root")
	check(visual.nickname_label.visible and visual.nickname_label.text == "Тест Player", "Opponent nickname")
	check(visual.nickname_label.modulate.a == 1 and visual.parts.head.modulate.a == 1, "Children inherit opacity without multiplying it twice")
	check(visual.parts.head.body_color == Color("ee6633") and visual.parts.head.outline_width == 0, "Opponent colors retained without strong outline")
	frame.jump_ready = false
	frame.dash_ready = false
	visual.present(frame)
	check(visual.parts.left_leg.emission < 0.2 and visual.parts.head.emission < 0.2, "Unavailable ability lights dimmed")
	frame.jump_ready = true
	frame.dash_ready = true
	visual.present(frame)
	check(visual.parts.left_leg.emission == 1 and visual.parts.head.emission == 1, "Restored lights")
	check(visual.parts.head.body_color == Color("ee6633"), "Readiness never replaces chosen body color")
	profile.body_color = "invalid"
	check(not visual.apply_profile(profile) and visual.appearance.body_color == Color("ee6633"), "Invalid profile leaves known appearance intact")
	visual.is_local = true
	for sector: int in 8:
		frame.state = PlayerStateMachine.State.DASH
		frame.dash_vector = Vector2.RIGHT.rotated(sector * PI / 4)
		visual.present(frame, Vector2.UP)
		check(is_equal_approx(visual.rig.rotation, frame.dash_vector.angle() + PI / 2), "Oriented Dash %d" % sector)
		check(visual.selected_direction == Vector2.ZERO, "Dash clears visual indicator")
	frame.state = PlayerStateMachine.State.WALL_SLIDE
	frame.wall_side = -1
	visual.present(frame)
	var lean: float = visual.rig.rotation
	frame.wall_side = 1
	visual.present(frame)
	check(is_equal_approx(visual.rig.rotation, -lean), "Wall-side pose mirrors")
	frame.state = PlayerStateMachine.State.JUMP
	frame.events = PlayerMotor.Event.DOUBLE_JUMPED
	visual.present(frame)
	check(visual.animation.current == PlayerAnimationMachine.Pose.DOUBLE_JUMP, "Extra jump event pose")
	frame.events = 0
	for tick: int in 11:
		visual.present(frame)
	check(visual.animation.current == PlayerAnimationMachine.Pose.JUMP, "Extra jump pose expires")
	frame.events = PlayerMotor.Event.LANDED
	frame.state = PlayerStateMachine.State.IDLE
	visual.present(frame)
	check(visual.animation.current == PlayerAnimationMachine.Pose.LANDING, "Landing pose")
	frame.events = 0
	for tick: int in 6:
		visual.present(frame)
	check(visual.animation.current == PlayerAnimationMachine.Pose.IDLE, "Landing expires")
	frame.state = PlayerStateMachine.State.RESPAWN
	visual.present(frame)
	frame.state = PlayerStateMachine.State.FALL
	visual.present(frame)
	check(visual.animation.current == PlayerAnimationMachine.Pose.RESPAWN, "One-tick respawn gets visible cosmetic hold")
	frame.state = PlayerStateMachine.State.DEATH
	visual.present(frame, Vector2.UP)
	for tick: int in 27:
		visual.present(frame)
	check(is_zero_approx(visual.parts.torso.modulate.a), "Death disperses modules in 0.45 seconds")
	frame.state = PlayerStateMachine.State.RESPAWN
	visual.present(frame)
	check(visual.parts.torso.modulate.a == 1 and visual.selected_direction == Vector2.ZERO, "Respawn rebuilds modules and clears selection")
	for module: String in visual.parts:
		check(visual.parts[module].scale == Vector2.ONE, "No squash/stretch: " + module)
	frame.state = PlayerStateMachine.State.RUN
	frame.speed_ratio = 0.3
	var machine := PlayerAnimationMachine.new()
	machine.advance(frame)
	var slow: float = machine.playback_speed
	frame.speed_ratio = 1
	machine.advance(frame)
	check(machine.playback_speed > slow, "Run frequency follows speed")
	for state: int in expected.size():
		frame.state = state as PlayerStateMachine.State
		machine.advance(frame)
		check(machine.current != PlayerAnimationMachine.Pose.FAST_FALL_RESERVED, "No Fast Fall gameplay mapping")
	var config := CharacterPresentationConfig.new()
	config.opponent_opacity = NAN
	check(not config.valid(), "Nonfinite presentation tuning rejected")
	visual.free()
	var gallery: Node2D = preload("res://dev_tools/character_gallery.tscn").instantiate()
	root.add_child(gallery)
	check(gallery.previews.size() == 28, "Gallery includes 14 local/opponent pairs")
	gallery.body_picker.color = Color("aa44dd")
	gallery.accent_picker.color = Color("ffee33")
	gallery.change_palette(Color.WHITE)
	check(gallery.previews[0].parts.head.body_color == Color("aa44dd"), "Developer color picker uses profile pipeline")
	check(gallery.previews[1].parts.head.accent_color == Color("ffee33"), "Opponent retains selected accent")
	gallery.readiness.button_pressed = false
	gallery._physics_process(1.0 / 60)
	check(not gallery.previews[0].dash_ready and not gallery.previews[1].jump_ready, "Gallery ability toggle drives cues")
	gallery.free()
	if failures == 0:
		print("PROJECTVELOCITY_M4_OK (%d checks)" % checks)
	quit(0 if failures == 0 else 1)
