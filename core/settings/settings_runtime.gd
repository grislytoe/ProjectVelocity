class_name SettingsRuntime
extends Node
## Applies supported engine properties; presentation observers read detached settings.

signal changed
static var visual: Dictionary = {}
var current: Dictionary = {}
var filter_material: ShaderMaterial
var quiet_cue: AudioStreamWAV
var world: WorldPresentation

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("settings_runtime")
	world = WorldPresentation.new()
	add_child(world)
	var overlay := CanvasLayer.new()
	overlay.layer = 90
	add_child(overlay)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	filter_material = ShaderMaterial.new()
	filter_material.shader = preload("res://visuals/settings_filter.gdshader")
	rect.material = filter_material
	overlay.add_child(rect)
	for bus: String in SettingsValues.BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
		if bus != "Master":
			AudioServer.set_bus_send(AudioServer.get_bus_index(bus), "Master")
	for slot: String in ["MenuMusic", "LevelMusic", "SFX", "UI", "Ambience"]:
		var player := AudioStreamPlayer.new()
		player.name = slot
		player.bus = "Music" if slot.ends_with("Music") else slot
		add_child(player)
	# Short low-amplitude placeholder, never automatically played by headless tests.
	quiet_cue = AudioStreamWAV.new()
	quiet_cue.format = AudioStreamWAV.FORMAT_16_BITS
	quiet_cue.mix_rate = 22050
	var samples := PackedByteArray()
	samples.resize(2204)
	for index: int in 1102:
		var envelope: float = sin(PI * index / 1102.0)
		var sample: int = roundi(sin(TAU * 440 * index / 22050.0) * envelope * 600)
		samples.encode_s16(index * 2, sample)
	quiet_cue.data = samples
	$UI.stream = quiet_cue
	$SFX.stream = quiet_cue

func cue(bus: String) -> void:
	if DisplayServer.get_name() != "headless" and bus in ["UI", "SFX"]:
		(get_node(bus) as AudioStreamPlayer).play()

func apply(settings: Dictionary) -> void:
	current = settings.duplicate(true)
	visual = current.duplicate(true)
	world.apply(settings.video)
	Engine.max_fps = int(settings.video.fps_limit)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.video.vsync
			else DisplayServer.VSYNC_DISABLED)
	var window: Window = get_tree().root
	window.min_size = DisplayAdapter.MINIMUM
	window.content_scale_size = Vector2i(1920, 1080)
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	window.canvas_item_default_texture_filter = SettingsValues.PRESETS[settings.video.effects_quality].filter
	filter_material.set_shader_parameter("correction", SettingsValues.CORRECTIONS.find(settings.accessibility.colorblind))
	filter_material.set_shader_parameter("high_contrast", settings.accessibility.high_contrast)
	filter_material.set_shader_parameter("post_intensity", settings.video.post_intensity)
	for bus: String in SettingsValues.BUSES:
		var index: int = AudioServer.get_bus_index(bus)
		var volume: float = settings.audio[bus.to_lower()]
		AudioServer.set_bus_volume_db(index, linear_to_db(volume) if volume > 0 else -80.0)
		AudioServer.set_bus_mute(index, settings.audio.mutes[bus.to_lower()] or volume <= 0)
	changed.emit()

static func access(field: String, fallback: Variant) -> Variant:
	return visual.get("accessibility", {}).get(field, fallback)

static func video(field: String, fallback: Variant) -> Variant:
	return visual.get("video", {}).get(field, fallback)
