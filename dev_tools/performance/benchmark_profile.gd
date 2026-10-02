class_name BenchmarkProfile
extends Resource
## Visual-only benchmark configuration. Simulation/network rates are deliberately absent.

@export_enum("quality", "low", "balanced", "performance") var preset: String = "balanced"
@export var resolution: Vector2i = Vector2i(1280, 800)
@export var paced: bool = true
@export var vsync: bool = true
@export var fps_limit: int = 60


func valid() -> bool:
	return preset in ["quality", "low", "balanced", "performance"] \
		and resolution in [Vector2i(1920, 1080), Vector2i(1280, 800)] \
		and fps_limit in [0, 60] and (not paced or fps_limit == 60)


func effects_quality() -> String:
	# Low is the approved 1080p target label; it uses the Performance visual budget.
	return "performance" if preset == "low" else preset


func world_resolution() -> Vector2i:
	return Vector2i(1280, 720) if resolution == Vector2i(1280, 800) else resolution


func settings() -> Dictionary:
	var values: Dictionary = SaveSchema.defaults().settings
	values.video.resolution = [resolution.x, resolution.y]
	values.video.effects_quality = effects_quality()
	values.video.vsync = vsync if paced else false
	values.video.fps_limit = fps_limit if paced else 0
	return values
