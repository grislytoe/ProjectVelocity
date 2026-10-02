extends SceneTree
## CPU-only deterministic checks; CI never certifies machine-specific frame thresholds.

const Stats = preload("res://dev_tools/performance/benchmark_stats.gd")
const Profile = preload("res://dev_tools/performance/benchmark_profile.gd")
var failures: int = 0
var checks: int = 0


func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error("M24: " + label)


func _initialize() -> void:
	var values: Array[float] = [40.0, 10.0, 30.0, 20.0]
	check(Stats.percentile(values, 0.50) == 20.0, "nearest-rank p50")
	check(Stats.percentile(values, 0.95) == 40.0, "nearest-rank p95")
	check(is_nan(Stats.percentile([], 0.5)), "empty percentile is unavailable")
	var summary: Dictionary = Stats.summarize(values)
	check(summary.samples == 4 and summary.max_ms == 40.0 and summary.over_33_333 == 1,
		"summary counts deterministic thresholds")
	check(Stats.classify(Stats.summarize([16.0, 16.0]), false).status == "BLOCKED",
		"uncertified hardware cannot pass")
	check(Stats.classify(Stats.summarize([16.0, 34.0]), true).status == "FAIL",
		"stutter fails engineering convention")
	check(Stats.classify(Stats.summarize([16.0, 34.0]), false, false).status == "BLOCKED",
		"composition smoke records metrics without applying machine thresholds")
	var profile := Profile.new()
	profile.preset = "low"
	profile.resolution = Vector2i(1920, 1080)
	check(profile.valid() and profile.effects_quality() == "performance", "1080p Low visual mapping")
	profile.resolution = Vector2i(1280, 800)
	profile.preset = "balanced"
	check(profile.valid() and profile.world_resolution() == Vector2i(1280, 720), "Deck competitive frame")
	var invalid := {"schema": 1}
	check(not Stats.validate_result(invalid).is_empty(), "missing metrics fail schema")
	var caps: HazardCapsConfig = preload("res://gameplay/hazards/default_caps.tres")
	check(caps.projectiles_per_target == 5 and caps.projectiles_global == 10 \
		and caps.engaging_turrets_per_target == 3, "gameplay caps unchanged")
	check(Engine.physics_ticks_per_second == 60 and BuildInfo.NETWORK_PROTOCOL_VERSION == 5 \
		and BuildInfo.NETWORK_WIRE_REVISION == 4 and SaveSchema.CURRENT_VERSION == 5,
		"simulation/wire/save cadence unchanged")
	var exports := ConfigFile.new()
	check(exports.load("res://export_presets.cfg") == OK and "dev_tools/*" in String(
		exports.get_value("preset.0", "exclude_filter", "")), "benchmark excluded from production export")
	var benchmark: PackedScene = load("res://dev_tools/performance_benchmark.tscn")
	var benchmark_root: Node = benchmark.instantiate() if benchmark != null else null
	check(benchmark_root != null, "benchmark scene composes")
	if benchmark_root != null: benchmark_root.free()
	if failures == 0:
		print("PROJECTVELOCITY_M24_PERFORMANCE_OK checks=", checks)
	quit(0 if failures == 0 else 1)
