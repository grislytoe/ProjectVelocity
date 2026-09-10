class_name MapChecksum
extends RefCounted
## PV-MAP-1: explicit gameplay metadata + semantic Resource/SceneState + baked code bundle.
## All numbers use little-endian IEEE754 bytes, never locale-dependent decimal formatting.

static func compute(map: MapDefinition) -> String:
	if map == null:
		return ""
	var report := MapDiagnostics.new()
	var payload: Array = ["PV-MAP-1", MapCodeManifest.DIGEST, map.map_id, map.map_version,
		map.map_type, map.grid_pixels, map.strict_order, map.par_time_ticks, map.death_bounds,
		map.start, map.finish, map.checkpoints]
	if not MapDependencies.available(map.scene_path, report):
		return ""
	payload.append(load(map.scene_path))
	# Include default configs/preloaded actors even when a scene omits an export override.
	for path: String in MapCodeManifest.DATA_PATHS:
		if not MapDependencies.available(path, report):
			return ""
		payload.append([path, load(path)])
	for placement: MapSectionPlacement in map.sections:
		if placement == null or placement.section == null:
			return ""
		var section: MapSectionDefinition = placement.section
		if not MapDependencies.available(section.scene_path, report):
			return ""
		payload.append([placement.instance_id, placement.transform, placement.next_id,
			section.section_id, section.entrance, section.exit, section.major_geometry,
			load(section.scene_path)])
	var canonical: String = encode(payload, report)
	if not report.valid():
		print("[MapChecksum] " + report.describe())
	return canonical.sha256_text() if report.valid() else ""

static func encode(value: Variant, report: MapDiagnostics, stack: Array = []) -> String:
	if value == null:
		return "n;"
	match typeof(value):
		TYPE_NIL:
			return "n;"
		TYPE_BOOL:
			return "t;" if value else "f;"
		TYPE_INT:
			return "i%d;" % value
		TYPE_FLOAT:
			if not is_finite(value):
				report.add("number", "checksum", "Non-finite content")
				return ""
			return "d" + PackedFloat64Array([0.0 if value == 0 else value]).to_byte_array().hex_encode()
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var string: String = str(value)
			return "s%d:%s" % [string.to_utf8_buffer().size(), string]
		TYPE_VECTOR2:
			return "v" + encode([value.x, value.y], report, stack)
		TYPE_RECT2:
			return "r" + encode([value.position, value.size], report, stack)
		TYPE_TRANSFORM2D:
			return "x" + encode([value.x, value.y, value.origin], report, stack)
		TYPE_COLOR:
			return "c" + encode([value.r, value.g, value.b, value.a], report, stack)
		TYPE_VECTOR2I:
			return "j" + encode([value.x, value.y], report, stack)
		TYPE_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, \
		TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, \
		TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			var result: String = "a%d[" % value.size()
			for item: Variant in value:
				result += encode(item, report, stack)
			return result + "]"
		TYPE_DICTIONARY:
			var pairs: Array[String] = []
			for key: Variant in value:
				pairs.append(encode(key, report, stack) + encode(value[key], report, stack))
			pairs.sort()
			return "m%d{%s}" % [pairs.size(), "".join(pairs)]
		TYPE_OBJECT:
			if value is Script:
				var path: String = value.resource_path
				if not MapCodeManifest.PATHS.has(path):
					report.add("dependency", path, "Script is not in the verified gameplay code bundle")
				return "script:" + path
			if not value is Resource or value in stack:
				report.add("resource", "checksum", "Unsupported object or cyclic resource")
				return ""
			var nested: Array = stack.duplicate()
			nested.append(value)
			if value is PackedScene:
				return encode(_scene(value, report), report, nested)
			var properties: Dictionary = {"@class": value.get_class()}
			for property: Dictionary in value.get_property_list():
				var key: String = property.name
				if property.usage & PROPERTY_USAGE_STORAGE and key not in ["resource_name", "resource_path"] \
					and not key.begins_with("metadata/_editor"):
					properties[key] = value.get(key)
			return encode(properties, report, nested)
		_:
			report.add("resource", "checksum", "Unsupported canonical type %d" % typeof(value))
			return ""

static func _scene(scene: PackedScene, report: MapDiagnostics) -> Array:
	# Materialize inherited/default properties without entering the tree. This makes
	# editor-added type/script/default overrides equivalent to omitted inherited values.
	var root: Node = scene.instantiate()
	var nodes: Array = []
	_node(root, root, nodes, report)
	root.free()
	return nodes

static func _node(node: Node, root: Node, nodes: Array, report: MapDiagnostics) -> void:
	var properties: Dictionary = {}
	for property: Dictionary in node.get_property_list():
		var key: String = property.name
		if property.usage & PROPERTY_USAGE_STORAGE and key not in ["editor_description", "scene_file_path"] \
			and not key.begins_with("metadata/_editor"):
			properties[key] = node.get(key)
	var groups: Array = Array(node.get_groups())
	groups.sort()
	# SceneState only exposes this scene's own connections. Inspect resolved nodes
	# so inherited/nested persistent connections and their bind arguments participate.
	var connections: Array = []
	var signals: Array[Dictionary] = node.get_signal_list()
	signals.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.name < b.name)
	for signal_info: Dictionary in signals:
		for connection: Dictionary in node.get_signal_connection_list(signal_info.name):
			if connection.flags & Object.CONNECT_PERSIST == 0:
				continue
			var callback: Callable = connection.callable
			var target: Object = callback.get_object()
			if not target is Node or (target != root and not root.is_ancestor_of(target)):
				report.add("connection", str(root.get_path_to(node)), "Persistent target must belong to this scene")
				continue
			connections.append([signal_info.name, root.get_path_to(target), callback.get_method(),
				connection.flags, callback.get_bound_arguments(), callback.get_unbound_arguments_count()])
	nodes.append([root.get_path_to(node), node.get_class(), groups, properties, connections])
	for child: Node in node.get_children():
		_node(child, root, nodes, report)
