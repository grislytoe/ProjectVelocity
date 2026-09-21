class_name NameKeyboard
extends Window
## Exclusive controller-compatible text entry. Cancel never mutates the parent form.

signal accepted(value: String)
var value: String = ""
var russian: bool = false
var lowercase: bool = false
var code_mode: bool = false
var field: LineEdit
var keys: GridContainer

func _ready() -> void:
	title = tr("UI_KEYBOARD")
	size = Vector2i(980, 610)
	unresizable = true
	exclusive = true
	transient = true
	wrap_controls = true
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.theme = IndustrialTheme.create()
	add_child(margin)
	var column := VBoxContainer.new()
	margin.add_child(column)
	field = LineEdit.new()
	field.text = value
	field.max_length = 0 if code_mode else 15 # Validate pasted text without silent truncation.
	field.custom_minimum_size.y = 54
	column.add_child(field)
	keys = GridContainer.new()
	keys.columns = 11
	column.add_child(keys)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	for entry: Array in [["UI_ALPHABET", _alphabet], ["UI_CASE", _case], ["UI_SPACE", _space],
		["UI_DELETE", _delete], ["UI_DONE", _accept], ["UI_CANCEL", _cancel]]:
		if code_mode and entry[0] in ["UI_ALPHABET", "UI_CASE", "UI_SPACE"]:
			continue
		var item := Button.new()
		item.text = tr(entry[0])
		item.custom_minimum_size.y = 54
		item.pressed.connect(entry[1])
		actions.add_child(item)
	close_requested.connect(_cancel)
	_build_keys()

func _build_keys() -> void:
	for child: Node in keys.get_children():
		child.free()
	var alphabet: String = "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ" if russian else "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	if lowercase:
		alphabet = alphabet.to_lower()
	alphabet += "0123456789_-"
	if code_mode:
		alphabet = JoinCode.ALPHABET
	for character: String in alphabet:
		var item := Button.new()
		item.text = character
		item.custom_minimum_size = Vector2(74, 62)
		item.pressed.connect(func() -> void:
			if field.text.length() < (6 if code_mode else 15):
				field.text += character)
		keys.add_child(item)
	(keys.get_child(0) as Button).grab_focus.call_deferred()

func _alphabet() -> void:
	russian = not russian
	_build_keys()

func _case() -> void:
	lowercase = not lowercase
	_build_keys()

func _space() -> void:
	if field.text.length() < 15:
		field.text += " "

func _delete() -> void:
	field.text = field.text.left(-1)

func _accept() -> void:
	accepted.emit(field.text)
	queue_free()

func _cancel() -> void:
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_input_as_handled()
		_cancel()
