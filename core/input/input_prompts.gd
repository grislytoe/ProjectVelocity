class_name InputPrompts
extends RefCounted
## Asset-independent prompt descriptors; UI may replace tokens with glyphs later.


static func family_from_name(device_name: String) -> String:
	var name: String = device_name.to_lower()
	if "steam" in name:
		return "steam_deck"
	if "dual" in name or "playstation" in name or "ps4" in name or "ps5" in name:
		return "playstation"
	if "nintendo" in name or "switch" in name:
		return "nintendo"
	if "xbox" in name or "xinput" in name:
		return "xbox"
	return "generic"


static func descriptor(token: String, family: String) -> Dictionary:
	if token.is_empty():
		return {"token": "unbound", "label": TranslationServer.translate("INPUT_UNBOUND")}
	var event: InputEvent = InputBindings.event_for(token)
	if event is InputEventKey:
		return {"token": token, "label": event.as_text_physical_keycode()}
	if event is InputEventMouseButton:
		return {"token": token, "label": TranslationServer.translate("INPUT_MOUSE_BUTTON") % event.button_index}
	if event is InputEventJoypadMotion:
		var axis_names: Array[String] = ["LS X", "LS Y", "RS X", "RS Y", "LT", "RT"]
		return {"token": family + "/" + token,
			"label": axis_names[event.axis] + ("−" if event.axis_value < 0 else "+")}
	var labels: Array[String] = [
		"A", "B", "X", "Y", "Back", "Guide", "Start", "LS", "RS", "LB", "RB",
		"D-Pad ↑", "D-Pad ↓", "D-Pad ←", "D-Pad →"]
	if family == "playstation":
		labels = ["×", "○", "□", "△", "Create", "PS", "Options", "L3", "R3", "L1", "R1",
			"D-Pad ↑", "D-Pad ↓", "D-Pad ←", "D-Pad →"]
	elif family == "nintendo":
		labels = ["B", "A", "Y", "X", "−", "Home", "+", "LS", "RS", "L", "R",
			"D-Pad ↑", "D-Pad ↓", "D-Pad ←", "D-Pad →"]
	var index: int = (event as InputEventJoypadButton).button_index
	var label: String = labels[index] if index < labels.size() else (
		TranslationServer.translate("INPUT_PAD_BUTTON") % index)
	if family == "generic":
		label = TranslationServer.translate("INPUT_PAD_BUTTON") % index
	return {"token": family + "/" + token, "label": label}
