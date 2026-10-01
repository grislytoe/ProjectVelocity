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
	result.set_color("font_color", "Label", ArtPalette.TEXT)
	result.set_color("font_color", "Button", ArtPalette.TEXT)
	result.set_color("font_outline_color", "Label", ArtPalette.BACKGROUND)
	result.set_constant("outline_size", "Label", 1)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_focus_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", ArtPalette.READY)
	result.set_color("font_disabled_color", "Button", ArtPalette.TEXT_MUTED.darkened(0.25))
	result.set_stylebox("normal", "Button", box(ArtPalette.PANEL_RAISED, ArtPalette.STEEL))
	result.set_stylebox("hover", "Button", box(Color("203d47"), ArtPalette.ROUTE))
	result.set_stylebox("pressed", "Button", box(Color("244b43"), ArtPalette.READY, 2))
	result.set_stylebox("focus", "Button", box(Color.TRANSPARENT, ArtPalette.FOCUS, 3))
	result.set_stylebox("disabled", "Button", box(Color("10171d"), Color("2a363d")))
	result.set_stylebox("panel", "PanelContainer", box(Color("0b141cf5"), ArtPalette.STEEL, 2))
	result.set_stylebox("normal", "LineEdit", box(ArtPalette.VOID, ArtPalette.STEEL))
	result.set_stylebox("focus", "LineEdit", box(Color.TRANSPARENT, ArtPalette.FOCUS, 3))
	result.set_stylebox("focus", "HSlider", box(Color.TRANSPARENT, ArtPalette.FOCUS, 3))
	var separator := StyleBoxLine.new()
	separator.color = ArtPalette.ROUTE_DIM
	separator.thickness = 2
	separator.grow_begin = 8
	separator.grow_end = 8
	result.set_stylebox("separator", "HSeparator", separator)
	result.set_constant("separation", "VBoxContainer", 12)
	result.set_constant("separation", "HBoxContainer", 16)
	return result
