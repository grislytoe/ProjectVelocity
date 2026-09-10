extends SceneTree
## One checksum implementation for authoring, CI, runtime, exports and PB records.

func _initialize() -> void:
	for path: String in ["res://map_data/training_circuit.tres", "res://map_data/industrial_foundry.tres"]:
		if not bake(path):
			quit(1)
			return
	quit()

func bake(path: String) -> bool:
	var map: MapDefinition = load(path) as MapDefinition
	var report: MapDiagnostics = MapValidator.inspect(map, false)
	if not report.valid():
		printerr(report.describe())
		return false
	var hash_value: String = map.checksum()
	if hash_value.is_empty():
		printerr("Cannot canonicalize map dependencies")
		return false
	if "--update" in OS.get_cmdline_user_args():
		var source: String = FileAccess.get_file_as_string(path)
		var pattern := RegEx.new()
		pattern.compile('declared_checksum = "[^"]*"')
		source = pattern.sub(source, 'declared_checksum = "' + hash_value + '"')
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(source)
		file.close()
	elif map.declared_checksum != hash_value:
		printerr("Stale PV-MAP-1 declared checksum")
		return false
	print("PV_MAP_HASH_OK=" + hash_value)
	return true
