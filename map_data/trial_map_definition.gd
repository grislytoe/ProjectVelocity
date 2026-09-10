class_name TrialMapDefinition
extends MapDefinition

## M10 source compatibility only. No second hash or independent manifest.

func _init() -> void:
	var map: MapDefinition = MapCatalog.training()
	if map == null:
		return
	for property: Dictionary in map.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property.usage & PROPERTY_USAGE_STORAGE:
			set(property.name, map.get(property.name))
