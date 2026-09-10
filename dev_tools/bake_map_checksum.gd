extends SceneTree
## One checksum implementation for authoring, CI, runtime, exports and PB records.

func _initialize() -> void:
	var map: MapDefinition = MapCatalog.training()
	var report: MapDiagnostics = MapValidator.inspect(map, false)
	if not report.valid():
		printerr(report.describe())
		quit(1)
		return
	var hash_value: String = map.checksum()
	if hash_value.is_empty():
		printerr("Cannot canonicalize map dependencies")
		quit(1)
		return
	if "--update" in OS.get_cmdline_user_args():
		var path: String = "res://map_data/training_circuit.tres"
		var source: String = FileAccess.get_file_as_string(path)
		var pattern := RegEx.new()
		pattern.compile('declared_checksum = "[^"]*"')
		source = pattern.sub(source, 'declared_checksum = "' + hash_value + '"')
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(source)
		file.close()
	elif map.declared_checksum != hash_value:
		printerr("Stale PV-MAP-1 declared checksum")
		quit(1)
		return
	print("PV_MAP_HASH_OK=" + hash_value)
	quit()
