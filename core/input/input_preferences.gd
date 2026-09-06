class_name InputPreferences
extends Node
## Debounced persistence adapter. The input layer itself performs no disk I/O.

var store: SaveStore
var layer: InputLayer
var _timer: Timer
var _dirty: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = 0.5
	_timer.timeout.connect(flush)
	add_child(_timer)
	layer.configuration_changed.connect(_queue_save)
	layer.device_changed.connect(_on_device_changed)


func _on_device_changed(_device_type: String, _device_id: int) -> void:
	_queue_save()


func _queue_save() -> void:
	_dirty = true
	_timer.start()


func flush() -> bool:
	if not _dirty:
		return true
	_timer.stop()
	if store.read_only:
		return false
	store.data.settings.controls.input = layer.config.duplicate(true)
	store.data.profile.last_input_device = layer.last_device
	var success: bool = store.save()
	_dirty = not success
	return success


func _exit_tree() -> void:
	if _dirty:
		flush()
