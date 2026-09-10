class_name MapCatalog
extends RefCounted
## Explicit local catalog; no filesystem scan or network discovery at runtime.

static func training() -> MapDefinition:
	var path: String = "res://map_data/training_circuit.tres"
	if not MapDependencies.available(path, MapDiagnostics.new()):
		return null
	var resource: Resource = load(path)
	return resource.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as MapDefinition if resource is MapDefinition else null

static func official() -> Array[MapDefinition]:
	return [industrial(), training()]

static func industrial() -> MapDefinition:
	var path: String = "res://map_data/industrial_foundry.tres"
	if not MapDependencies.available(path, MapDiagnostics.new()):
		return null
	var resource: Resource = load(path)
	return resource.duplicate_deep(Resource.DEEP_DUPLICATE_ALL) as MapDefinition if resource is MapDefinition else null

static func validate_catalog(maps: Array[MapDefinition]) -> MapDiagnostics:
	var report := MapDiagnostics.new()
	var ids: Array[String] = []
	for map: MapDefinition in maps:
		if map == null or map.map_id in ids:
			report.add("catalog", "catalog", "Null entry or duplicate stable map ID")
			continue
		ids.append(map.map_id)
		report.errors.append_array(MapValidator.inspect(map).errors)
	return report
