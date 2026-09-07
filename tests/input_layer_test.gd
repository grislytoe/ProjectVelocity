extends SceneTree
## Synthetic Godot input events and hotplug adapter events; no physical controller required.

var _checks: int = 0
var _failures: int = 0
var _layer: InputLayer
var _devices: int = 0
var _prompts: int = 0
var _connections: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _send(token: String, pressed: bool = true, device: int = -1) -> void:
	var event: InputEvent = InputBindings.event_for(token, device)
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		event.pressed = pressed
	elif event is InputEventJoypadMotion and not pressed:
		event.axis_value = 0.0
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _run() -> void:
	Input.use_accumulated_input = false
	_layer = InputLayer.new()
	_layer.watch_hardware = false
	_layer.device_changed.connect(func(_type: String, _id: int) -> void: _devices += 1)
	_layer.prompts_changed.connect(func() -> void: _prompts += 1)
	_layer.connection_changed.connect(func(_id: int, _connected: bool) -> void: _connections += 1)
	root.add_child(_layer)
	await process_frame
	_check(InputBindings.valid_config(InputBindings.configuration()), "Default input config valid")
	for profile: String in InputBindings.PROFILES:
		for action: String in InputBindings.ACTIONS:
			for token: String in InputBindings.defaults(profile)[action]:
				_check(InputBindings.valid_token(profile, token), "Default token valid: " + token)
	_check(InputMap.has_action(_layer.action_name("jump")), "Player actions registered")
	_send(InputBindings.key(KEY_D))
	_check(_layer.sample().movement.is_equal_approx(Vector2.RIGHT), "D moves right")
	_send(InputBindings.key(KEY_W))
	_check(is_equal_approx(_layer.sample().movement.length(), 1.0), "Diagonal speed normalized")
	_send(InputBindings.key(KEY_D), false)
	_send(InputBindings.key(KEY_W), false)
	_send(InputBindings.key(KEY_SPACE))
	_check(_layer.sample().jump_pressed and _layer.sample().jump_held, "Jump pressed/held intent")
	_send(InputBindings.key(KEY_SPACE), false)
	_check(_layer.sample().jump_released and not _layer.sample().jump_held, "Jump release intent")
	_send(InputBindings.key(KEY_SHIFT))
	_check(_layer.sample().dash_pressed, "Shift requests Dash")
	_send(InputBindings.key(KEY_SHIFT), false)
	_send(InputBindings.key(KEY_RIGHT))
	_check(_layer.sample().dash_direction.is_equal_approx(Vector2.RIGHT), "Arrow selects Dash")
	_send(InputBindings.key(KEY_RIGHT), false)
	await process_frame
	_check(_layer.sample().dash_direction == Vector2.RIGHT and not _layer.sample().dash_pressed,
		"Selection persists without auto-firing")
	_send(InputBindings.key(KEY_RIGHT))
	_layer.sample()
	_layer.clear_dash_selection()
	_check(_layer.sample().dash_direction == Vector2.ZERO, "Held direction does not relatch after clear")
	_send(InputBindings.key(KEY_RIGHT), false)
	_layer.sample()
	_send(InputBindings.key(KEY_UP))
	_check(_layer.sample().dash_direction == Vector2.UP, "New selection after clearing")
	_layer.clear_transient_state()
	_check(_layer.sample().movement == Vector2.ZERO, "Focus/state clear releases movement")
	for sector: int in 8:
		var expected: Vector2 = Vector2.RIGHT.rotated(sector * PI / 4.0)
		_check(InputLayer.quantize_dash(expected).is_equal_approx(expected), "Eight-way sector center")
		_check(InputLayer.quantize_dash(expected.rotated(0.1)).is_equal_approx(expected), "Sector interior")
	_check(InputLayer.quantize_dash(Vector2.ZERO) == Vector2.ZERO, "Neutral does not select")
	_check(InputLayer.radial_deadzone(Vector2(0.2, 0), 0.2) == Vector2.ZERO, "Deadzone boundary")
	_check(InputLayer.radial_deadzone(Vector2(0.6, 0), 0.2).is_equal_approx(Vector2(0.5, 0)),
		"Radial deadzone rescales smoothly")
	_check(InputLayer.radial_deadzone(Vector2.ONE, 0.2).length() <= 1.00001, "Analog clamp")

	_layer.update_connection(42, true, "DualSense Wireless Controller")
	_check(_connections == 1 and _layer.last_device == "keyboard_mouse", "Connect does not steal focus")
	var drift := InputEventJoypadMotion.new()
	drift.device = 42
	drift.axis = JOY_AXIS_LEFT_X
	drift.axis_value = 0.1
	Input.parse_input_event(drift)
	Input.flush_buffered_events()
	_check(_layer.last_device == "keyboard_mouse", "Drift does not switch prompts")
	_send("axis:0:1", true, 42)
	_check(_layer.last_device == "controller" and _layer.active_pad == 42, "Stick selects active pad")
	_check(_layer.sample().movement == Vector2.RIGHT, "Left stick maps movement")
	_check(_layer.prompt("dash").label == "R1", "PlayStation prompt")
	_send("axis:2:-1", true, 42)
	_send("axis:3:1", true, 42)
	_check(_layer.sample().dash_direction.is_equal_approx(Vector2(-1, 1).normalized()),
		"Right stick quantizes to diagonal")
	_send("button:10", true, 42)
	_check(_layer.sample().dash_pressed, "RB/R1 Dash")
	_layer.update_connection(43, true, "Nintendo Switch Pro")
	_send("button:0", true, 43)
	_check(_layer.active_pad == 43 and _layer.prompt("jump").label == "B", "Nintendo positional prompt")
	_check(_layer.sample().movement == Vector2.ZERO, "Other pad axes cannot leak into active pad")
	_layer.update_connection(43, false)
	_check(_layer.last_device == "keyboard_mouse" and _layer.sample().movement == Vector2.ZERO,
		"Active disconnect falls back and clears state")
	_check(not InputMap.has_action(_layer.action_name("jump", "gamepad", 43)), "Disconnected map removed")
	_layer.update_connection(42, false)
	_layer.update_connection(42, true, "Xbox Controller")
	_send("button:0", true, 42)
	_check(_layer.prompt("jump").label == "A", "Reconnect restores mappings")
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(3, 0)
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	_check(_layer.last_device == "keyboard_mouse", "Mouse switches prompts")
	_check(_devices > 0 and _prompts > _devices, "Device and prompt notifications")
	for family: String in ["xbox", "steam_deck", "playstation", "nintendo", "generic"]:
		_check(not InputPrompts.descriptor("button:0", family).label.is_empty(), "Prompt family: " + family)
	_check(InputPrompts.family_from_name("Steam Virtual Gamepad") == "steam_deck", "Deck detection")
	_check(_layer.set_options({"movement": 0.25, "dash": 0.3, "activity": 0.35}, "steam_deck"),
		"Options configurable")
	_check(not _layer.set_options({"movement": 1.0, "dash": 0.3, "activity": 0.35}, "auto"),
		"Unsafe deadzone rejected")
	_check(not _layer.rebind("keyboard", "jump", [InputBindings.key(KEY_D)]).ok,
		"Gameplay binding conflict rejected")
	_check(not _layer.rebind("keyboard", "jump", ["axis:0:1"]).ok, "Profile types kept separate")
	_check(not _layer.rebind("keyboard", "ui_accept", []).ok, "Cannot strand UI accept")
	_check(_layer.rebind("keyboard", "jump", [InputBindings.key(KEY_J)]).ok, "Rebind Jump")
	_check(_layer.bindings("gamepad", "jump") == ["button:0"], "Keyboard edit preserves gamepad")
	_send(InputBindings.key(KEY_SPACE))
	_check(not _layer.sample().jump_held, "Old binding removed")
	_send(InputBindings.key(KEY_SPACE), false)
	_send(InputBindings.key(KEY_J))
	_check(_layer.sample().jump_held and "J" in _layer.prompt("jump").label, "New binding and prompt")
	_send(InputBindings.key(KEY_J), false)
	_check(_layer.begin_rebind("keyboard", "jump"), "Begin capture")
	_send(InputBindings.key(KEY_K))
	_check(_layer.last_rebind_result.get("ok", false), "Capture event commits binding")
	_check(not _layer.sample().jump_held, "Captured press not delivered as gameplay")
	_layer.reset_profile("keyboard")
	_check(_layer.bindings("keyboard", "jump") == [InputBindings.key(KEY_SPACE)], "Reset profile")
	_send(InputBindings.key(KEY_ENTER))
	_check(Input.is_action_pressed("ui_accept"), "Godot UI action available")
	_send(InputBindings.key(KEY_ENTER), false)
	_layer.notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	_check(not _layer.sample().jump_held, "Focus loss clears held intent")

	var directory: String = OS.get_cache_dir().path_join("project_velocity_m2-test-" + PlayerProfileData.new_uuid())
	var store := SaveStore.new(directory)
	_check(store.open(), "Isolated store")
	var old: Dictionary = store.data.duplicate(true)
	old.save_version = 1
	old.settings.controls.erase("input")
	old.settings.controls.bindings = {"future_jump": ["keyboard:space"]}
	var migrated: Dictionary = SaveSchema.decode(old)
	_check(migrated.status == "valid" and migrated.data.save_version == 2, "M1 to M2 migration")
	_check(migrated.data.profile.uuid == old.profile.uuid and
		migrated.data.settings.controls.bindings == old.settings.controls.bindings, "Migration preserves M1 data")
	var prefs := InputPreferences.new()
	prefs.store = store
	prefs.layer = _layer
	root.add_child(prefs)
	_check(_layer.rebind("keyboard", "jump", [InputBindings.key(KEY_J)]).ok, "Saved rebind")
	_send("button:0", true, 42)
	_check(prefs.flush(), "Persist input preferences explicitly")
	var loaded := SaveStore.new(directory)
	_check(loaded.open(), "Reload input preferences")
	_check(loaded.data.settings.controls.input.profiles.keyboard.jump == [InputBindings.key(KEY_J)],
		"Keyboard profile survives reload")
	_check(loaded.data.profile.last_input_device == "controller", "Last active device persisted")
	var invalid: Dictionary = loaded.data.duplicate(true)
	invalid.settings.controls.input.deadzones.dash = "bad"
	_check(SaveSchema.decode(invalid).status == "invalid", "Invalid saved input config rejected")
	prefs.queue_free()
	_layer.queue_free()
	await process_frame
	for filename: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(filename))
	DirAccess.remove_absolute(directory)
	_check(not InputMap.has_action("pv_keyboard_jump"), "Owned input actions cleaned up")
	var hardware_layer := InputLayer.new()
	root.add_child(hardware_layer)
	Input.joy_connection_changed.emit(99, true)
	_check(hardware_layer.connected_pads.has(99), "Godot hotplug signal reaches adapter")
	Input.joy_connection_changed.emit(99, false)
	_check(not hardware_layer.connected_pads.has(99), "Godot disconnect signal reaches adapter")
	hardware_layer.queue_free()
	await process_frame
	print("Physical controllers available: %d" % Input.get_connected_joypads().size())
	if _failures == 0:
		print("PROJECTVELOCITY_M2_TESTS_OK (%d checks)" % _checks)
	quit(0 if _failures == 0 else 1)
