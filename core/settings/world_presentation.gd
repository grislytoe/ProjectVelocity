class_name WorldPresentation
extends Node
## Render the world at the selected pixel budget, retaining a fixed competitive view.

const REFERENCE := Vector2i(1920, 1080)
var viewport: SubViewport

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.name = "WorldViewport"
	viewport.world_2d = World2D.new()
	viewport.size = REFERENCE
	viewport.size_2d_override = REFERENCE
	viewport.size_2d_override_stretch = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.gui_disable_input = true
	add_child(viewport)
	var canvas := CanvasLayer.new()
	canvas.layer = -1
	add_child(canvas)
	var output := TextureRect.new()
	output.texture = viewport.get_texture()
	output.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	output.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	output.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(output)
	output.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func render_size(resolution: Array) -> Vector2i:
	# Fit 16:9 inside the requested dimensions; output letterboxing stays on the root.
	var factor: float = minf(maxi(int(resolution[0]), DisplayAdapter.MINIMUM.x) / float(REFERENCE.x),
		maxi(int(resolution[1]), DisplayAdapter.MINIMUM.y) / float(REFERENCE.y))
	return Vector2i(Vector2(REFERENCE) * factor)

func apply(video: Dictionary) -> void:
	viewport.size = render_size(video.resolution)
	viewport.canvas_item_default_texture_filter = SettingsValues.PRESETS[video.effects_quality].filter
