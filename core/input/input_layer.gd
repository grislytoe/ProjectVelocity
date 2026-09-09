class_name InputLayer
extends Node
## Godot Input adapter. Owns application InputMap entries, not gameplay state.

signal device_changed(device_type: String, device_id: int)
signal prompts_changed
signal configuration_changed
signal connection_changed(device_id: int, connected: bool)

var watch_hardware: bool = true
var last_device: String = "keyboard_mouse"
var active_pad: int = -1
var connected_pads: Dictionary = {}
var config: Dictionary = InputBindings.configuration()
var _owned_actions: Array[StringName] = []
var _ui_backup: Dictionary = {}
var _selected_dash: Vector2 = Vector2.ZERO
var _last_dash_vector: Vector2 = Vector2.ZERO
var _capture_profile: String = ""
var _capture_action: String = ""
var last_rebind_result: Dictionary = {}
var _entry_release_gate: Array[InputEvent] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if watch_hardware:
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
		for id: int in Input.get_connected_joypads():
			connected_pads[id] = Input.get_joy_name(id)
	_rebuild()
	if connected_pads.is_empty():
		_select_device("keyboard_mouse", -1)
	elif last_device == "controller":
		_select_device("controller", int(connected_pads.keys()[0]))


func configure(value: Dictionary, previous_device: String = "keyboard_mouse") -> bool:
	if not InputBindings.valid_config(value) or previous_device not in ["keyboard_mouse", "controller"]:
		return false
	config = value.duplicate(true)
	last_device = previous_device
	if is_inside_tree():
		_rebuild()
	return true


func bindings(profile: String, action: String) -> Array:
	action = InputBindings.canonical_action(action)
	var overrides: Dictionary = config.profiles.get(profile, {})
	return overrides.get(action, InputBindings.defaults(profile).get(action, [])).duplicate()


func action_name(action: String, profile: String = "", device_id: int = -1) -> StringName:
	var chosen: String = profile
	if chosen.is_empty():
		chosen = "gamepad" if last_device == "controller" else "keyboard"
	if chosen == "keyboard":
		return StringName("pv_keyboard_" + action)
	var id: int = active_pad if device_id < 0 else device_id
	return StringName("pv_pad_%d_%s" % [id, action])


func _install(name: StringName, tokens: Array, device: int, deadzone: float) -> void:
	if String(name).begins_with("ui_") and not _ui_backup.has(name):
		_ui_backup[name] = {"events": InputMap.action_get_events(name),
			"deadzone": InputMap.action_get_deadzone(name)}
	if not InputMap.has_action(name):
		InputMap.add_action(name, deadzone)
	Input.action_release(name)
	InputMap.action_erase_events(name)
	InputMap.action_set_deadzone(name, deadzone)
	for token: String in tokens:
		InputMap.action_add_event(name, InputBindings.event_for(token, device))
	if not String(name).begins_with("ui_"):
		_owned_actions.append(name)


func _rebuild() -> void:
	clear_transient_state()
	for name: StringName in _owned_actions:
		InputMap.erase_action(name)
	_owned_actions.clear()
	for action: String in InputBindings.ACTIONS:
		_install(action_name(action, "keyboard"), bindings("keyboard", action), -1, 0.0)
		for id: int in connected_pads:
			_install(action_name(action, "gamepad", id), bindings("gamepad", action), id, 0.0)
		if action.begins_with("ui_"):
			_install(StringName(action), bindings("keyboard", action), -1, 0.5)
			for id: int in connected_pads:
				for token: String in bindings("gamepad", action):
					InputMap.action_add_event(StringName(action), InputBindings.event_for(token, id))
	prompts_changed.emit()


func _on_joy_connection_changed(id: int, connected: bool) -> void:
	update_connection(id, connected, Input.get_joy_name(id) if connected else "")


func update_connection(id: int, connected: bool, device_name: String = "") -> void:
	if connected:
		connected_pads[id] = device_name
	else:
		connected_pads.erase(id)
	_rebuild()
	if not connected and id == active_pad:
		_select_device("keyboard_mouse", -1)
	connection_changed.emit(id, connected)


func _select_device(device_type: String, id: int) -> void:
	if last_device == device_type and active_pad == id:
		return
	last_device = device_type
	active_pad = id
	_selected_dash = Vector2.ZERO
	_last_dash_vector = Vector2.ZERO
	device_changed.emit(last_device, active_pad)
	prompts_changed.emit()


func _input(event: InputEvent) -> void:
	observe_event(event)
	if not _capture_action.is_empty():
		get_viewport().set_input_as_handled()
		var token: String = InputBindings.capture(_capture_profile, event)
		if not token.is_empty():
			last_rebind_result = rebind(_capture_profile, _capture_action, [token])
			_capture_action = ""
			_capture_profile = ""
			clear_transient_state()
			get_viewport().set_input_as_handled()


func observe_event(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_select_device("keyboard_mouse", -1)
	elif event is InputEventMouseButton and event.pressed:
		_select_device("keyboard_mouse", -1)
	elif event is InputEventMouseMotion and event.relative.length() >= 2.0:
		_select_device("keyboard_mouse", -1)
	elif event is InputEventJoypadButton and event.pressed and connected_pads.has(event.device):
		_select_device("controller", event.device)
	elif event is InputEventJoypadMotion and connected_pads.has(event.device) and (
		absf(event.axis_value) > float(config.deadzones.activity)):
		_select_device("controller", event.device)


static func radial_deadzone(vector: Vector2, threshold: float) -> Vector2:
	var length: float = vector.length()
	if length <= threshold or is_equal_approx(length, threshold):
		return Vector2.ZERO
	return vector.normalized() * clampf((length - threshold) / (1.0 - threshold), 0.0, 1.0)


static func quantize_dash(vector: Vector2) -> Vector2:
	if vector.is_zero_approx():
		return Vector2.ZERO
	var sector: int = posmod(int(floor(vector.angle() / (PI / 4.0) + 0.5)), 8)
	return Vector2.RIGHT.rotated(sector * PI / 4.0).snapped(Vector2(0.000001, 0.000001)).normalized()


func _vector(prefix: String, deadzone: float) -> Vector2:
	var raw := Vector2(
		Input.get_action_raw_strength(action_name(prefix + "_right")) -
			Input.get_action_raw_strength(action_name(prefix + "_left")),
		Input.get_action_raw_strength(action_name(prefix + "_down")) -
			Input.get_action_raw_strength(action_name(prefix + "_up")))
	return radial_deadzone(raw, deadzone)


func sample() -> InputFrame:
	var frame := InputFrame.new()
	if not _entry_release_gate.is_empty():
		for event: InputEvent in _entry_release_gate:
			if _hardware_held(event):
				return frame
		_entry_release_gate.clear()
		clear_transient_state()
	if not _capture_action.is_empty() or (last_device == "controller" and active_pad < 0):
		return frame
	frame.movement = _vector("move", float(config.deadzones.movement))
	frame.dash_pressed = Input.is_action_just_pressed(action_name("dash"))
	var direction: Vector2 = quantize_dash(_vector("move", float(config.deadzones.dash)))
	# A fresh trigger may reuse held aim after the previous successful Dash cleared selection.
	if not direction.is_zero_approx() and (
		frame.dash_pressed or not direction.is_equal_approx(_last_dash_vector)):
		_selected_dash = direction
	_last_dash_vector = direction
	frame.dash_direction = _selected_dash
	frame.jump_pressed = Input.is_action_just_pressed(action_name("jump"))
	frame.jump_held = Input.is_action_pressed(action_name("jump"))
	frame.jump_released = Input.is_action_just_released(action_name("jump"))
	frame.pause_pressed = Input.is_action_just_pressed(action_name("pause"))
	frame.restart_held = Input.is_action_pressed(action_name("restart"))
	return frame


func quarantine_gameplay_entry() -> void:
	# UI entry requires release of physically held gameplay inputs, including key repeats.
	# This gate is only requested by navigation, never by ordinary Solo quick restart.
	_entry_release_gate.clear()
	for action: String in ["move_left", "move_right", "move_up", "move_down", "jump", "dash", "restart"]:
		for token: String in bindings("keyboard", action):
			var event: InputEvent = InputBindings.event_for(token, -1)
			if _hardware_held(event):
				_entry_release_gate.append(event)
		for id: int in connected_pads:
			for token: String in bindings("gamepad", action):
				var event: InputEvent = InputBindings.event_for(token, id)
				if _hardware_held(event):
					_entry_release_gate.append(event)


func _hardware_held(event: InputEvent) -> bool:
	if event is InputEventKey:
		return Input.is_physical_key_pressed(event.physical_keycode)
	if event is InputEventMouseButton:
		return Input.is_mouse_button_pressed(event.button_index)
	if event is InputEventJoypadButton:
		return connected_pads.has(event.device) and Input.is_joy_button_pressed(event.device, event.button_index)
	if event is InputEventJoypadMotion:
		return connected_pads.has(event.device) and Input.get_joy_axis(event.device, event.axis) * event.axis_value > float(config.deadzones.movement)
	return false


func clear_dash_selection() -> void:
	_selected_dash = Vector2.ZERO


func clear_transient_state(preserve_restart: bool = false) -> void:
	for name: StringName in _owned_actions:
		if preserve_restart and String(name).ends_with("_restart"):
			continue
		Input.action_release(name)
	for action: String in InputBindings.ACTIONS:
		if action.begins_with("ui_") and InputMap.has_action(action):
			Input.action_release(action)
	_selected_dash = Vector2.ZERO
	_last_dash_vector = Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		clear_transient_state()
		cancel_rebind()


func begin_rebind(profile: String, action: String) -> bool:
	if profile not in InputBindings.PROFILES or action not in InputBindings.ACTIONS:
		return false
	clear_transient_state()
	_capture_profile = profile
	_capture_action = action
	last_rebind_result = {}
	return true


func cancel_rebind() -> void:
	_capture_profile = ""
	_capture_action = ""


func rebind(profile: String, action: String, tokens: Array) -> Dictionary:
	if profile not in InputBindings.PROFILES or action not in InputBindings.ACTIONS:
		return {"ok": false, "message_key": "INPUT_BINDING_INVALID"}
	action = InputBindings.canonical_action(action)
	var proposed: Dictionary = config.duplicate(true)
	proposed.profiles[profile][action] = tokens.duplicate()
	if not InputBindings.valid_config(proposed):
		return {"ok": false, "message_key": "INPUT_BINDING_INVALID"}
	for other: String in InputBindings.ACTIONS:
		if other != InputBindings.canonical_action(other):
			continue
		if other == action or other.begins_with("ui_") != action.begins_with("ui_"):
			continue
		for token: String in tokens:
			if token in bindings(profile, other):
				return {"ok": false, "message_key": "INPUT_BINDING_CONFLICT", "action": other}
	config = proposed
	_rebuild()
	configuration_changed.emit()
	return {"ok": true}


func reset_profile(profile: String) -> void:
	if profile not in InputBindings.PROFILES:
		return
	config.profiles[profile] = {}
	_rebuild()
	configuration_changed.emit()


func set_options(deadzones: Dictionary, family: String) -> bool:
	var proposed: Dictionary = config.duplicate(true)
	proposed.deadzones = deadzones.duplicate(true)
	proposed.prompt_family = family
	if not InputBindings.valid_config(proposed):
		return false
	config = proposed
	clear_transient_state()
	prompts_changed.emit()
	configuration_changed.emit()
	return true


func prompt(action: String) -> Dictionary:
	if action not in InputBindings.ACTIONS:
		return {}
	var profile: String = "gamepad" if last_device == "controller" else "keyboard"
	var tokens: Array = bindings(profile, action)
	var family: String = config.prompt_family
	if family == "auto":
		family = InputPrompts.family_from_name(connected_pads.get(active_pad, ""))
	return InputPrompts.descriptor(tokens[0] if not tokens.is_empty() else "", family)


func _exit_tree() -> void:
	clear_transient_state()
	for name: StringName in _owned_actions:
		InputMap.erase_action(name)
	for name: StringName in _ui_backup:
		InputMap.action_erase_events(name)
		InputMap.action_set_deadzone(name, _ui_backup[name].deadzone)
		for event: InputEvent in _ui_backup[name].events:
			InputMap.action_add_event(name, event)
