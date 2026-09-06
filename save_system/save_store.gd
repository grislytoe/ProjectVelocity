class_name SaveStore
extends RefCounted
## Single-writer local persistence with validated staging and a previous-good backup.

const MAX_SAVE_BYTES: int = 4 * 1024 * 1024
const DEFAULT_DIRECTORY: String = "user://saves"

var data: Dictionary = {}
var notification_key: String = ""
var source: String = ""
var read_only: bool = false
var directory: String


func _init(save_directory: String = DEFAULT_DIRECTORY) -> void:
	directory = ProjectSettings.globalize_path(save_directory)


func _path(filename: String) -> String:
	return directory.path_join(filename)


func _read(filename: String) -> Dictionary:
	var path: String = _path(filename)
	if not FileAccess.file_exists(path):
		return {"status": "missing"}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "io_error"}
	if file.get_length() > MAX_SAVE_BYTES:
		return {"status": "invalid"}
	var content: String = file.get_as_text()
	var json := JSON.new()
	if json.parse(content) != OK:
		return {"status": "invalid"}
	return SaveSchema.decode(json.data)


func open() -> bool:
	notification_key = ""
	read_only = false
	var primary: Dictionary = _read("save.json")
	var backup: Dictionary = _read("save.backup.json")
	# Never downgrade a newer save, or overwrite files that could not be read.
	read_only = primary.status in ["unsupported", "io_error"] or (
		backup.status in ["unsupported", "io_error"])
	if primary.status == "valid":
		data = primary.data
		source = "primary"
	elif backup.status == "valid":
		data = backup.data
		source = "backup"
		notification_key = "SAVE_RECOVERED"
	else:
		data = SaveSchema.defaults()
		source = "defaults"
		if primary.status != "missing" or backup.status != "missing":
			notification_key = "SAVE_RESET"
	if read_only:
		notification_key = "SAVE_UNSUPPORTED" if (
			primary.status == "unsupported" or backup.status == "unsupported") else "SAVE_IO_ERROR"
		return true
	# Persist creation, migration, recovery and launch time. UUID is never regenerated on load.
	data.profile.last_launch_at = maxi(
		int(data.profile.created_at), int(Time.get_unix_time_from_system()))
	return save()


func save() -> bool:
	if read_only:
		return false
	if not SaveSchema.validate(data):
		notification_key = "SAVE_INVALID"
		return false
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return _io_failure()
	var primary: Dictionary = _read("save.json")
	var backup: Dictionary = _read("save.backup.json")
	if primary.status in ["unsupported", "io_error"] or backup.status in ["unsupported", "io_error"]:
		read_only = true
		notification_key = "SAVE_UNSUPPORTED" if (
			primary.status == "unsupported" or backup.status == "unsupported") else "SAVE_IO_ERROR"
		return false
	# Verify new data on disk before touching either existing generation.
	if not _stage("save.tmp", data):
		return _io_failure()
	if primary.status == "valid":
		if not _stage("backup.tmp", primary.data):
			return _io_failure()
		if not _replace("backup.tmp", "save.backup.json"):
			return _io_failure()
	elif primary.status != "missing":
		# Keep corrupt bytes for diagnosis before replacing with backup/defaults.
		if not _quarantine("save.json"):
			return _io_failure()
	if backup.status == "invalid" and primary.status != "valid":
		if not _quarantine("save.backup.json"):
			return _io_failure()
	if not _replace("save.tmp", "save.json"):
		return _io_failure()
	return true


func _stage(filename: String, value: Dictionary) -> bool:
	var text: String = JSON.stringify(value, "\t")
	if text.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return false
	var file := FileAccess.open(_path(filename), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.flush()
	var result: Error = file.get_error()
	file.close()
	return result == OK and _read(filename).status == "valid"


func _replace(staged: String, target: String) -> bool:
	# Same-directory rename; never delete the destination as a fallback.
	return DirAccess.rename_absolute(_path(staged), _path(target)) == OK


func _quarantine(filename: String) -> bool:
	var suffix: String = PlayerProfileData.new_uuid()
	if suffix.is_empty():
		return false
	return DirAccess.rename_absolute(
		_path(filename), _path(filename + ".corrupt-" + suffix)) == OK


func _io_failure() -> bool:
	notification_key = "SAVE_IO_ERROR"
	return false
