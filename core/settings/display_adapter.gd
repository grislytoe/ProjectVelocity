class_name DisplayAdapter
extends RefCounted
## Native window adapter. Confirmation owns persistence, never this adapter.

func snapshot() -> Dictionary:
	return {"mode": DisplayServer.window_get_mode(),
		"borderless": DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS),
		"size": DisplayServer.window_get_size(), "position": DisplayServer.window_get_position()}

func supported(size: Vector2i) -> bool:
	var desktop: Vector2i = DisplayServer.screen_get_size()
	return size.x >= 640 and size.y >= 360 and size.x <= desktop.x and size.y <= desktop.y

func choices() -> Array:
	var result: Array = []
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(1600, 900),
		Vector2i(1920, 1080), Vector2i(2560, 1080), Vector2i(2560, 1440),
		Vector2i(3440, 1440), Vector2i(3840, 2160)]:
		if supported(size):
			result.append([size.x, size.y])
	var native: Vector2i = DisplayServer.screen_get_size()
	if supported(native) and not result.has([native.x, native.y]):
		result.append([native.x, native.y])
	return result

func apply(video: Dictionary) -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var size := Vector2i(int(video.resolution[0]), int(video.resolution[1]))
	if not supported(size):
		return false
	if video.window_mode != "windowed" and size != DisplayServer.screen_get_size():
		return false
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, video.window_mode == "borderless")
	DisplayServer.window_set_size(size)
	if video.window_mode == "fullscreen":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	elif video.window_mode == "borderless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		var usable: Rect2i = DisplayServer.screen_get_usable_rect()
		DisplayServer.window_set_position(usable.position + (usable.size - size) / 2)
	return true

func matches(video: Dictionary) -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var mode: int = DisplayServer.window_get_mode()
	if video.window_mode == "windowed":
		return mode == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_size() == Vector2i(
			int(video.resolution[0]), int(video.resolution[1]))
	return mode in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

func restore(state: Dictionary) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, state.borderless)
	DisplayServer.window_set_size(state.size)
	DisplayServer.window_set_position(state.position)
	DisplayServer.window_set_mode(state.mode)
