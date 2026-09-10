class_name MapAssembly
extends Node2D
## Owns section instances. Prepared detached, then adopted once by the course.

var sections: Dictionary[StringName, Node2D] = {}

func assemble(definition: MapDefinition) -> void:
	for placement: MapSectionPlacement in definition.sections:
		var section := (load(placement.section.scene_path) as PackedScene).instantiate() as Node2D
		section.name = "Section%d" % (sections.size() + 1)
		section.transform = placement.transform
		sections[placement.instance_id] = section
		add_child(section)

func point_position(point: MapPoint, respawn: bool = false) -> Vector2:
	var section: Node2D = sections[point.section_id]
	var marker := section.get_node(point.respawn_anchor if respawn else point.anchor) as Marker2D
	return section.transform * MapValidator.relative_transform(marker, section).origin

func bind_hazards(world: HazardWorld) -> void:
	for section: Node2D in sections.values():
		for node: Node in section.find_children("*", "Turret", true, false):
			(node as Turret).bind(world, [&"local", &"absent"])
