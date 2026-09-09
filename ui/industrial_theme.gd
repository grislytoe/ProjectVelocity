class_name IndustrialTheme
extends RefCounted

static func box(fill: Color, border: Color, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func create() -> Theme:
	var result := Theme.new()
	result.default_font_size = 24
	result.set_color("font_color", "Label", Color("dfebed"))
	result.set_color("font_color", "Button", Color("dfebed"))
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_focus_color", "Button", Color.WHITE)
	result.set_color("font_disabled_color", "Button", Color("819096"))
	result.set_stylebox("normal", "Button", box(Color("152832"), Color("39515c")))
	result.set_stylebox("hover", "Button", box(Color("234450"), Color("73e7d2")))
	result.set_stylebox("pressed", "Button", box(Color("326557"), Color("d0fff0")))
	result.set_stylebox("focus", "Button", box(Color.TRANSPARENT, Color("edc675"), 3))
	result.set_stylebox("disabled", "Button", box(Color("121d25"), Color("293640")))
	result.set_stylebox("panel", "PanelContainer", box(Color("0e1a23"), Color("36515e")))
	result.set_stylebox("normal", "LineEdit", box(Color("09131c"), Color("607c87")))
	result.set_stylebox("focus", "LineEdit", box(Color.TRANSPARENT, Color("edc675"), 3))
	result.set_stylebox("focus", "HSlider", box(Color.TRANSPARENT, Color("edc675"), 3))
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 16)
	return result
