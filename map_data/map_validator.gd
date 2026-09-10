class_name MapValidator
extends RefCounted
## Detached inspection: no _ready, physics, targets or callbacks before acceptance.

static func inspect(map: MapDefinition, verify_checksum: bool = true) -> MapDiagnostics:
	var report := MapDiagnostics.new()
	if map == null:
		report.add("definition", "map", "Definition is null")
		return report
	if map.map_id.strip_edges().is_empty() or map.map_id.contains(":") or map.map_version <= 0:
		report.add("identity", "map", "Nonempty stable ID without ':' and positive version required")
	if map.name_key.is_empty() or map.description_key.is_empty() or map.difficulty_key.is_empty() \
		or map.map_type not in ["official", "custom"] or map.expected_duration_seconds <= 0 \
		or map.par_time_ticks <= 0:
		report.add("metadata", "map", "Translation keys, type, positive seconds and par ticks required")
	if not map.grid_pixels.is_finite() or map.grid_pixels.x <= 0 or map.grid_pixels.y <= 0:
		report.add("grid", "map", "Grid dimensions must be finite positive world pixels")
		return report
	if map.sections.is_empty():
		report.add("sections", "map", "At least one section required")
	if not map.death_bounds.position.is_finite() or not map.death_bounds.size.is_finite() \
		or map.death_bounds.size.x <= 0 or map.death_bounds.size.y <= 0:
		report.add("bounds", "map", "Finite positive fall DeathZone bounds required")
	if not MapDependencies.available(map.scene_path, report):
		return report
	var shell: Resource = load(map.scene_path)
	if not shell is PackedScene:
		report.add("scene", map.scene_path, "Map scene must be a PackedScene")
	else:
		var node: Node = shell.instantiate()
		if not node is SoloCourse or node.get_child_count() != 0:
			report.add("scene", map.scene_path, "Expected empty SoloCourse assembly host")
		elif node.transform != Transform2D.IDENTITY or node.top_level:
			report.add("transform", map.scene_path, "Assembly host must retain the map coordinate frame")
		node.free()
	var roots: Dictionary[StringName, Node2D] = {}
	var definition_ids: Dictionary = {}
	var entrances: Array[Vector2] = []
	var exits: Array[Vector2] = []
	var footprints: Array[Rect2] = []
	for index: int in map.sections.size():
		var placement: MapSectionPlacement = map.sections[index]
		var location: String = "sections[%d]" % index
		if placement == null or placement.section == null:
			report.add("section", location, "Null placement or section definition")
			continue
		if placement.instance_id == &"" or roots.has(placement.instance_id):
			report.add("id", location, "Empty or duplicate section instance ID")
			continue
		var section: MapSectionDefinition = placement.section
		if section.section_id == &"" or (definition_ids.has(section.section_id) \
			and definition_ids[section.section_id] != section):
			report.add("id", location, "Definition IDs must identify one reusable resource")
		definition_ids[section.section_id] = section
		var expected_next: StringName = &""
		if index + 1 < map.sections.size() and map.sections[index + 1] != null:
			expected_next = map.sections[index + 1].instance_id
		if placement.next_id != expected_next:
			report.add("link", location, "next_id must reference the next placement; final exit is terminal")
		if not translation_only(placement.transform) or not on_grid(placement.transform.origin, map.grid_pixels):
			report.add("transform", location, "Only finite, grid-aligned translations are supported")
		if not MapDependencies.available(section.scene_path, report):
			continue
		var packed: Resource = load(section.scene_path)
		if not packed is PackedScene:
			report.add("scene", location, "Section must be a PackedScene")
			continue
		var raw: Node = packed.instantiate()
		if not raw is Node2D:
			report.add("scene", location, "Section root must be Node2D")
			raw.free()
			continue
		var root := raw as Node2D
		roots[placement.instance_id] = root
		inspect_nodes(root, report, location)
		if root.transform != Transform2D.IDENTITY:
			report.add("transform", location, "Section root must have identity transform")
		var entrance: Marker2D = marker(root, section.entrance, report, location + "/entrance")
		var exit: Marker2D = marker(root, section.exit, report, location + "/exit")
		if section.entrance == section.exit:
			report.add("anchor", location, "Entrance and exit must be distinct markers")
		var local_rects: Array[Rect2] = []
		if section.major_geometry.is_empty():
			report.add("geometry", location, "Declare major floor collision paths")
		var shape_paths: Array[NodePath] = []
		for path: NodePath in section.major_geometry:
			var shape := root.get_node_or_null(path) as CollisionShape2D if local_path(path) else null
			if path in shape_paths or shape == null or not shape.shape is RectangleShape2D \
				or shape.disabled or not shape.get_parent() is StaticBody2D \
				or shape.get_parent() is AnimatableBody2D:
				report.add("geometry", location + "/" + str(path), "Unique active static rectangle required")
				continue
			shape_paths.append(path)
			var body := shape.get_parent() as StaticBody2D
			var pose: Transform2D = relative_transform(shape, root)
			var size: Vector2 = shape.shape.size
			var rect := Rect2(pose.origin - size / 2, size)
			if not translation_only(pose) or not size.is_finite() or size.x <= 0 or size.y <= 0 \
				or not body.constant_linear_velocity.is_zero_approx() \
				or not is_zero_approx(body.constant_angular_velocity) or body.collision_layer & 1 == 0 \
				or not on_grid(rect.position, map.grid_pixels) or not on_grid(rect.end, map.grid_pixels):
				report.add("grid", location + "/" + str(path), "Major collision bounds must use the grid and stationary support")
			local_rects.append(rect)
			var world_rect := Rect2(rect.position + placement.transform.origin, size)
			for other: Rect2 in footprints:
				if world_rect.intersects(other):
					report.add("overlap", location, "Major collision footprints overlap")
			footprints.append(world_rect)
		if entrance != null and exit != null:
			var a: Vector2 = relative_transform(entrance, root).origin
			var b: Vector2 = relative_transform(exit, root).origin
			if not on_grid(a, map.grid_pixels) or not on_grid(b, map.grid_pixels):
				report.add("grid", location, "Seam anchors must use the section-local grid")
			if not floor_edge(a, local_rects, false) or not floor_edge(b, local_rects, true):
				report.add("seam_support", location, "Entrance/exit must meet left/right top edge of declared floor")
			entrances.append(a + placement.transform.origin)
			exits.append(b + placement.transform.origin)
	if entrances.size() == map.sections.size():
		for index: int in entrances.size() - 1:
			if not exits[index].is_equal_approx(entrances[index + 1]):
				report.add("seam", "sections[%d]" % index, "Exit and next entrance do not coincide in map space")
	var point_ids: Array[StringName] = []
	var points: Array[MapPoint] = [map.start]
	points.append_array(map.checkpoints)
	points.append(map.finish)
	var last_section: int = -1
	var used_anchors: Array[String] = []
	for index: int in points.size():
		var point: MapPoint = points[index]
		var location: String = "route[%d]" % index
		if point == null:
			report.add("point", location, "Start, Finish and checkpoint entries cannot be null")
			continue
		if point.point_id == &"" or point.point_id in point_ids:
			report.add("id", location, "Empty or duplicate route point ID")
		point_ids.append(point.point_id)
		if not roots.has(point.section_id):
			report.add("reference", location, "Unknown section instance")
			continue
		var section_index: int = -1
		for placement_index: int in map.sections.size():
			if map.sections[placement_index] != null and map.sections[placement_index].instance_id == point.section_id:
				section_index = placement_index
		if section_index < last_section or (index == 0 and section_index != 0) \
			or (index == points.size() - 1 and section_index != map.sections.size() - 1):
			report.add("order", location, "Route must follow section order from first Start to last Finish")
		last_section = section_index
		var root: Node2D = roots[point.section_id]
		marker(root, point.anchor, report, location)
		var anchor_id: String = str(point.section_id) + "/" + str(point.anchor)
		if anchor_id in used_anchors:
			report.add("point", location, "Route points cannot share the same trigger marker")
		used_anchors.append(anchor_id)
		if index != points.size() - 1:
			marker(root, point.respawn_anchor, report, location + "/respawn")
		if not point.trigger_size.is_finite() or point.trigger_size.x <= 0 or point.trigger_size.y <= 0:
			report.add("point", location, "Trigger dimensions must be finite positive pixels")
	for root: Node2D in roots.values():
		root.free()
	if verify_checksum and report.valid():
		var actual: String = map.checksum()
		if actual.is_empty() or actual != map.declared_checksum:
			report.add("checksum", map.map_id, "PV-MAP-1 content does not match declared checksum")
	return report

static func local_path(path: NodePath) -> bool:
	return not path.is_empty() and not path.is_absolute() and not str(path).contains("..") \
		and path.get_subname_count() == 0

static func marker(root: Node2D, path: NodePath, report: MapDiagnostics, location: String) -> Marker2D:
	var node := root.get_node_or_null(path) as Marker2D if local_path(path) else null
	if node == null or not translation_only(relative_transform(node, root)):
		report.add("anchor", location, "Missing local Marker2D or unsupported anchor transform")
		return null
	return node

static func relative_transform(node: Node2D, root: Node2D) -> Transform2D:
	var pose: Transform2D = node.transform
	var parent: Node = node.get_parent()
	while parent != root and parent != null:
		if parent is Node2D:
			pose = parent.transform * pose
		parent = parent.get_parent()
	return pose

static func translation_only(pose: Transform2D) -> bool:
	return pose.origin.is_finite() and pose.x == Vector2.RIGHT and pose.y == Vector2.DOWN

static func on_grid(point: Vector2, grid: Vector2) -> bool:
	return point.is_finite() and (point / grid).is_equal_approx((point / grid).round())

static func floor_edge(point: Vector2, rects: Array[Rect2], right: bool) -> bool:
	for rect: Rect2 in rects:
		if point.is_equal_approx(Vector2(rect.end.x if right else rect.position.x, rect.position.y)):
			return true
	return false

static func inspect_nodes(node: Node, report: MapDiagnostics, location: String) -> void:
	if node is PlayerController or node is PlayerLifecycle or node is HazardWorld \
		or node is CheckpointTrigger or node is FinishTrigger or node is StartBarrier:
		report.add("authority", location, "Actors, progress, triggers and pools belong to the assembly host")
	if node is Node2D:
		var pose: Transform2D = node.transform
		if node.top_level or not pose.origin.is_finite() or not pose.x.is_finite() or not pose.y.is_finite() \
			or is_zero_approx(pose.determinant()):
			report.add("transform", location, "Non-finite, singular or top-level transform breaks section coordinates")
	for property: Dictionary in node.get_property_list():
		if property.usage & PROPERTY_USAGE_STORAGE and property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value: Variant = node.get(property.name)
			if property.name == "config" and value == null:
				report.add("config", location, "Module config cannot be null")
			elif value is Resource and value.has_method("validate") and not value.call("validate"):
				report.add("config", location + "/" + property.name, "Invalid module config")
	for child: Node in node.get_children():
		inspect_nodes(child, report, location + "/" + str(child.name))
