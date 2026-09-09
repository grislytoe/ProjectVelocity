class_name SettingsSession
extends Node
## Owns detached drafts, applied presentation and a never-persisted display trial.

signal changed
signal preview_finished(kept: bool)
var store: SaveStore
var runtime: SettingsRuntime
var preferences: InputPreferences
var adapter: DisplayAdapter = DisplayAdapter.new()
var draft: Dictionary = {}
var applied: Dictionary = {}
var previous_display: Dictionary = {}
var previewing: bool = false
var remaining: float = 0.0
var error_key: String = ""
var editing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	applied = store.data.settings.duplicate(true)

func begin() -> void:
	if editing:
		return
	preferences.flush()
	preferences.editing = true
	editing = true
	draft = store.data.settings.duplicate(true)
	error_key = ""

func defaults(category: String) -> void:
	var factory: Dictionary = SettingsValues.defaults()
	SettingsValues.copy_known(draft[category], factory[category], factory[category])
	if category == "video":
		for field: String in ["screen_shake", "ui_scale", "hud_opacity"]:
			draft.accessibility[field] = factory.accessibility[field]
	elif category == "accessibility":
		draft.video.speed_intensity = factory.video.speed_intensity
	if category == "controls":
		preferences.layer.configure(draft.controls.input, preferences.layer.last_device)
	changed.emit()

func cancel() -> void:
	if previewing:
		revert()
	preferences.layer.cancel_rebind()
	preferences.layer.configure(store.data.settings.controls.input, preferences.layer.last_device)
	runtime.apply(store.data.settings)
	applied = store.data.settings.duplicate(true)
	draft = applied.duplicate(true)
	preferences.editing = false
	editing = false
	error_key = ""
	changed.emit()

func apply() -> bool:
	if previewing:
		return false
	draft.controls.input = preferences.layer.config.duplicate(true)
	var candidate: Dictionary = store.data.duplicate(true)
	candidate.settings = draft.duplicate(true)
	if not SaveSchema.validate(candidate):
		error_key = "SAVE_INVALID"
		return false
	var old: Dictionary = store.data.settings.video
	if old.resolution != draft.video.resolution or old.window_mode != draft.video.window_mode:
		previous_display = adapter.snapshot()
		if not adapter.apply(draft.video):
			adapter.restore(previous_display)
			error_key = "SET_DISPLAY_FAILED"
			return false
		previewing = true
		remaining = 15.0
		error_key = ""
		runtime.apply(draft)
		applied = draft.duplicate(true)
		changed.emit()
		return true
	return _commit()

func keep() -> bool:
	if not previewing:
		return false
	if not adapter.matches(draft.video):
		revert()
		error_key = "SET_DISPLAY_FAILED"
		return false
	if not _commit():
		revert()
		return false
	previewing = false
	preview_finished.emit(true)
	return true

func _commit() -> bool:
	# Merge only owned fields into the latest document, retaining other writers' data.
	var old: Dictionary = store.data.settings.duplicate(true)
	var factory: Dictionary = SettingsValues.defaults()
	for category: String in ["video", "audio", "accessibility"]:
		SettingsValues.copy_known(store.data.settings[category], draft[category], factory[category])
	store.data.settings.controls.input = draft.controls.input.duplicate(true)
	if not store.save():
		store.data.settings = old
		runtime.apply(old)
		applied = old.duplicate(true)
		error_key = "TT_SAVE_FAILED"
		return false
	runtime.apply(store.data.settings)
	applied = store.data.settings.duplicate(true)
	draft = applied.duplicate(true)
	error_key = ""
	changed.emit()
	return true

func revert() -> void:
	if not previewing:
		return
	previewing = false
	adapter.restore(previous_display)
	runtime.apply(store.data.settings)
	applied = store.data.settings.duplicate(true)
	draft.video.resolution = store.data.settings.video.resolution.duplicate()
	draft.video.window_mode = store.data.settings.video.window_mode
	preview_finished.emit(false)

func _process(delta: float) -> void:
	if previewing:
		remaining -= delta
		if remaining <= 0:
			revert()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_CLOSE_REQUEST]:
		revert()

func _exit_tree() -> void:
	# Teardown must not rebuild UI or call siblings which may already have exited.
	if previewing:
		previewing = false
		adapter.restore(previous_display)
