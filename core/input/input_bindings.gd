class_name InputBindings
extends RefCounted
## Serializable binding profiles. Physical key codes and standard Godot joy codes only.

const PROFILES: Array[String] = ["keyboard", "gamepad"]
const ACTIONS: Array[String] = [
	"move_left", "move_right", "move_up", "move_down",
	"dash_left", "dash_right", "dash_up", "dash_down",
	"jump", "dash", "pause", "restart",
	"ui_left", "ui_right", "ui_up", "ui_down",
	"ui_accept", "ui_cancel", "ui_focus_next", "ui_focus_prev"]
const FAMILIES: Array[String] = ["auto", "generic", "xbox", "playstation", "nintendo", "steam_deck"]


static func key(code: int, modifiers: int = 0) -> String:
	return "key:%d:%d" % [code, modifiers]


static func defaults(profile: String) -> Dictionary:
	if profile == "keyboard":
		return {
			"move_left": [key(KEY_A)], "move_right": [key(KEY_D)],
			"move_up": [key(KEY_W)], "move_down": [key(KEY_S)],
			"dash_left": [key(KEY_LEFT)], "dash_right": [key(KEY_RIGHT)],
			"dash_up": [key(KEY_UP)], "dash_down": [key(KEY_DOWN)],
			"jump": [key(KEY_SPACE)], "dash": [key(KEY_SHIFT)],
			"pause": [key(KEY_ESCAPE)], "restart": [key(KEY_R)],
			"ui_left": [key(KEY_LEFT)], "ui_right": [key(KEY_RIGHT)],
			"ui_up": [key(KEY_UP)], "ui_down": [key(KEY_DOWN)],
			"ui_accept": [key(KEY_ENTER), key(KEY_SPACE)], "ui_cancel": [key(KEY_ESCAPE)],
			"ui_focus_next": [key(KEY_TAB)], "ui_focus_prev": [key(KEY_TAB, 1)],
		}
	return {
		"move_left": ["axis:0:-1"], "move_right": ["axis:0:1"],
		"move_up": ["axis:1:-1"], "move_down": ["axis:1:1"],
		"dash_left": ["axis:2:-1"], "dash_right": ["axis:2:1"],
		"dash_up": ["axis:3:-1"], "dash_down": ["axis:3:1"],
		"jump": ["button:0"], "dash": ["button:10"],
		"pause": ["button:6"], "restart": ["button:3"],
		"ui_left": ["button:13", "axis:0:-1"], "ui_right": ["button:14", "axis:0:1"],
		"ui_up": ["button:11", "axis:1:-1"], "ui_down": ["button:12", "axis:1:1"],
		"ui_accept": ["button:0"], "ui_cancel": ["button:1"],
		"ui_focus_next": ["button:10"], "ui_focus_prev": ["button:9"],
	}


static func configuration() -> Dictionary:
	return {"profiles": {"keyboard": {}, "gamepad": {}},
		"deadzones": {"movement": 0.2, "dash": 0.25, "activity": 0.3},
		"prompt_family": "auto"}


static func valid_token(profile: String, token: Variant) -> bool:
	if not token is String:
		return false
	if profile == "keyboard":
		if PlayerProfileData.matches(token, "^key:[0-9]+:[0-9]+$"):
			var parts: PackedStringArray = token.split(":")
			return parts[1].to_int() > 0 and parts[1].to_int() < 33554432 and (
				parts[2].to_int() >= 0 and parts[2].to_int() <= 7)
		return PlayerProfileData.matches(token, "^mouse:[1-9]$") and int(token.substr(6)) <= 9
	if profile == "gamepad":
		if PlayerProfileData.matches(token, "^button:[0-9]{1,2}$"):
			return int(token.substr(7)) < JOY_BUTTON_MAX
		if PlayerProfileData.matches(token, "^axis:[0-5]:-?1$"):
			return true
	return false


static func valid_config(value: Variant) -> bool:
	if not value is Dictionary or not value.get("profiles") is Dictionary:
		return false
	if value.get("prompt_family") not in FAMILIES or not value.get("deadzones") is Dictionary:
		return false
	for zone: String in ["movement", "dash", "activity"]:
		var amount: Variant = value.deadzones.get(zone)
		if not (amount is float or amount is int) or not is_finite(float(amount)) or (
			float(amount) < 0.05 or float(amount) > 0.9):
			return false
	for profile: String in PROFILES:
		if not value.profiles.get(profile) is Dictionary:
			return false
		for action: Variant in value.profiles[profile]:
			if action not in ACTIONS:
				return false
			var tokens: Variant = value.profiles[profile][action]
			if not tokens is Array or tokens.size() > 4:
				return false
			if action in ["ui_accept", "ui_cancel"] and tokens.is_empty():
				return false
			for token: Variant in tokens:
				if not valid_token(profile, token):
					return false
	return true


static func event_for(token: String, device: int = -1) -> InputEvent:
	var parts: PackedStringArray = token.split(":")
	var code: int = parts[1].to_int()
	match parts[0]:
		"key":
			var event := InputEventKey.new()
			event.physical_keycode = code as Key
			var modifiers: int = parts[2].to_int()
			event.shift_pressed = (modifiers & 1) != 0
			event.ctrl_pressed = (modifiers & 2) != 0
			event.alt_pressed = (modifiers & 4) != 0
			return event
		"mouse":
			var event := InputEventMouseButton.new()
			event.button_index = code as MouseButton
			return event
		"button":
			var event := InputEventJoypadButton.new()
			event.button_index = code as JoyButton
			event.device = device
			return event
		"axis":
			var event := InputEventJoypadMotion.new()
			event.axis = code as JoyAxis
			event.axis_value = float(parts[2])
			event.device = device
			return event
	return null


static func capture(profile: String, event: InputEvent) -> String:
	if profile == "keyboard":
		if event is InputEventKey and event.pressed and not event.echo:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			var mask: int = int(event.shift_pressed) + 2 * int(event.ctrl_pressed) + 4 * int(event.alt_pressed)
			# Modifier-only bindings (notably Dash = Shift) must not include themselves.
			if code == KEY_SHIFT:
				mask &= ~1
			if code == KEY_CTRL:
				mask &= ~2
			if code == KEY_ALT:
				mask &= ~4
			return key(code, mask)
		if event is InputEventMouseButton and event.pressed:
			return "mouse:%d" % event.button_index
	if profile == "gamepad":
		if event is InputEventJoypadButton and event.pressed:
			return "button:%d" % event.button_index
		if event is InputEventJoypadMotion and absf(event.axis_value) >= 0.6:
			return "axis:%d:%d" % [event.axis, int(signf(event.axis_value))]
	return ""
