class_name DisplayAdapter
extends RefCounted
## Native window adapter. Confirmation owns persistence, never this adapter.

const MINIMUM := Vector2i(1280, 800)

func snapshot() -> Dictionary:
	return {"mode": DisplayServer.window_get_mode(),
		"borderless": DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
		"size": DisplayServer.window_get_size(), "position": DisplayServer.window_get_position()}

func supported(size: Vector2i) -> bool:
	var desktop: Vector2i = DisplayServer.screen_get_size()
	return size.x >= MINIMUM.x and size.y >= MINIMUM.y and size.x <= desktop.x and size.y <= desktop.y

func choices() -> Array:
	var result: Array = []
	for size: Vector2i in [Vector2i(1280, 800), Vector2i(1600, 900),
		Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(2560, 1440),
		Vector2i(3440, 1440), Vector2i(3840, 2160)]:
		if supported(size):
			result.append([size.x, size.y])
	var native: Vector2i = DisplayServer.screen_get_size()
	if supported(native) and not result.has([native.x, native.y]):
		result.append([native.x, native.y])
	return result

func apply(video: Dictionary) -> bool:
	var size := Vector2i(int(video.resolution[0]), int(video.resolution[1]))
	if size.x < MINIMUM.x or size.y < MINIMUM.y:
		return false
	if DisplayServer.get_name() == "headless":
		return true
	if not supported(size):
		return false
	# Resolution changes in fullscreen resize the render target, not the native window.
	var requested_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
	if video.window_mode == "fullscreen":
		requested_mode = DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	elif video.window_mode == "borderless":
		requested_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	if requested_mode != DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_mode() == requested_mode:
		return true
	# Keep Window's cached state synchronized with DisplayServer across layout updates.
	var window: Window = (Engine.get_main_loop() as SceneTree).root
	window.borderless = video.window_mode == "borderless"
	window.mode = Window.MODE_WINDOWED
	window.size = size
	if video.window_mode == "fullscreen":
		window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	elif video.window_mode == "borderless":
		window.mode = Window.MODE_FULLSCREEN
	else:
		var usable: Rect2i = DisplayServer.screen_get_usable_rect()
		window.position = usable.position + (usable.size - size) / 2
	return true

func matches(video: Dictionary) -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var mode: int = DisplayServer.window_get_mode()
	if video.window_mode == "windowed":
		return mode == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_size() == Vector2i(
			int(video.resolution[0]), int(video.resolution[1]))
	return mode == (DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if video.window_mode == "fullscreen"
		else DisplayServer.WINDOW_MODE_FULLSCREEN)

func restore(state: Dictionary) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window: Window = (Engine.get_main_loop() as SceneTree).root
	window.borderless = state.borderless
	if state.mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]:
		# Resizing a temporary window to desktop size corrupts Windows' restored window rect.
		window.mode = state.mode
		return
	window.mode = Window.MODE_WINDOWED
	window.size = state.size
	window.position = state.position
	window.mode = state.mode
