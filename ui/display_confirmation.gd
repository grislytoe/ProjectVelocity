class_name DisplayConfirmation
extends ConfirmationDialog
## Explicit action-based routing also supports remapped controller Cancel.

var finishing: bool = false

func route(event: InputEvent) -> bool:
	if finishing or event.is_echo():
		return false
	if event.is_action_pressed("ui_cancel"):
		finishing = true
		canceled.emit.call_deferred()
		return true
	if event.is_action_pressed("ui_accept"):
		finishing = true
		if gui_get_focus_owner() == get_ok_button():
			confirmed.emit.call_deferred()
		else:
			canceled.emit.call_deferred()
		return true
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right") or (
		event.is_action_pressed("ui_focus_next") or event.is_action_pressed("ui_focus_prev")):
		if gui_get_focus_owner() == get_ok_button():
			get_cancel_button().grab_focus()
		else:
			get_ok_button().grab_focus()
		return true
	return false

func _input(event: InputEvent) -> void:
	if route(event):
		set_input_as_handled()
