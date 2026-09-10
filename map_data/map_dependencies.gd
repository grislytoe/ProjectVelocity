class_name MapDependencies
extends RefCounted
## Check transitive external references before loading a PackedScene.

static func available(path: String, report: MapDiagnostics, seen: Dictionary = {}) -> bool:
	if seen.has(path):
		return true
	seen[path] = true
	if not path.begins_with("res://") or path.contains("..") or not ResourceLoader.exists(path):
		report.add("dependency", path, "Missing packaged resource or non-project path")
		return false
	var ok: bool = true
	for dependency: String in ResourceLoader.get_dependencies(path):
		# Godot emits uid::type::fallback-path, or a plain path.
		var target: String = dependency.get_slice("::", dependency.get_slice_count("::") - 1)
		if target.begins_with("uid://"):
			var uid: int = ResourceUID.text_to_id(target)
			target = ResourceUID.get_id_path(uid) if ResourceUID.has_id(uid) else ""
		if not available(target, report, seen):
			ok = false
	return ok
