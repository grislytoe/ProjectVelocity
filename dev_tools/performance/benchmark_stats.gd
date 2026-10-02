class_name BenchmarkStats
extends RefCounted
## Deterministic nearest-rank statistics and strict M24 result validation.

const SCHEMA: int = 1
const FRAME_TARGET_MS: float = 1000.0 / 60.0


static func percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty() or not is_finite(ratio) or ratio < 0.0 or ratio > 1.0:
		return NAN
	var ordered: Array[float] = values.duplicate()
	ordered.sort()
	var rank: int = maxi(1, ceili(ratio * ordered.size()))
	return ordered[rank - 1]


static func summarize(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"available": false, "reason": "no samples"}
	for value: float in values:
		if not is_finite(value) or value < 0.0:
			return {"available": false, "reason": "invalid samples"}
	var p99: float = percentile(values, 0.99)
	return {
		"available": true,
		"samples": values.size(),
		"p50_ms": percentile(values, 0.50),
		"p95_ms": percentile(values, 0.95),
		"p99_ms": p99,
		"max_ms": values.max(),
		# Convention: reciprocal of p99 frame time, not an average of the slowest 1%.
		"one_percent_low_fps": 1000.0 / p99 if p99 > 0.0 else 0.0,
		"over_16_667": values.filter(func(value: float) -> bool: return value > FRAME_TARGET_MS).size(),
		"over_25": values.filter(func(value: float) -> bool: return value > 25.0).size(),
		"over_33_333": values.filter(func(value: float) -> bool: return value > 1000.0 / 30.0).size(),
	}


static func summarize_counter(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return unavailable("no samples")
	for value: float in values:
		if not is_finite(value) or value < 0.0:
			return unavailable("invalid samples")
	return {"available": true, "samples": values.size(), "p50": percentile(values, 0.50),
		"p95": percentile(values, 0.95), "p99": percentile(values, 0.99), "max": values.max()}


static func unavailable(reason: String) -> Dictionary:
	return {"available": false, "reason": reason}


static func metric_valid(value: Variant) -> bool:
	if value is float or value is int:
		return is_finite(float(value)) and float(value) >= 0.0
	if not value is Dictionary or not value.has("available"):
		return false
	if value.available == false:
		return value.get("reason") is String and not String(value.reason).strip_edges().is_empty()
	if value.available != true:
		return false
	if value.size() <= 1:
		return false
	for key: String in value:
		if key != "available" and not metric_valid(value[key]):
			return false
	return true


static func validate_result(result: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key: String in ["schema", "scenario", "identity", "environment", "configuration",
		"sampling", "timing", "render", "objects", "memory", "pools", "leak", "first_use", "acceptance"]:
		if not result.has(key):
			errors.append("missing " + key)
	if not errors.is_empty():
		return errors
	if result.schema != SCHEMA:
		errors.append("unsupported schema")
	if not result.scenario is String or String(result.scenario).is_empty():
		errors.append("invalid scenario")
	for key: String in ["engine", "game_version", "build_number", "git_sha", "renderer"]:
		if not result.identity.has(key) or str(result.identity[key]).strip_edges().is_empty():
			errors.append("invalid identity." + key)
	for key: String in ["warmup_frames", "sample_frames", "seed"]:
		if not result.sampling.has(key) or not metric_valid(result.sampling[key]):
			errors.append("invalid sampling." + key)
	for group: String in ["timing", "render", "objects", "memory", "pools", "leak", "first_use"]:
		if not result[group] is Dictionary or result[group].is_empty():
			errors.append("empty " + group)
			continue
		for key: String in result[group]:
			var value: Variant = result[group][key]
			if value is Dictionary and value.has("available"):
				if not metric_valid(value): errors.append("invalid %s.%s" % [group, key])
			elif value is float or value is int:
				if not metric_valid(value): errors.append("invalid %s.%s" % [group, key])
	if result.acceptance.get("status") not in ["PASS", "BLOCKED", "FAIL"]:
		errors.append("invalid acceptance.status")
	return errors


static func classify(frame_summary: Dictionary, certified_hardware: bool) -> Dictionary:
	if not frame_summary.get("available", false):
		return {"status": "FAIL", "reason": "frame metrics unavailable"}
	# Engineering convention, not a master-spec quotation: paced p95 <= 17.5 ms
	# (one half-tick scheduler tolerance), p99 <= 25 ms, no >33.333 ms gameplay frame.
	var workload_ok: bool = float(frame_summary.p95_ms) <= 17.5 \
		and float(frame_summary.p99_ms) <= 25.0 and int(frame_summary.over_33_333) == 0
	if not workload_ok:
		return {"status": "FAIL", "reason": "local profile missed M24 engineering convention"}
	if not certified_hardware:
		return {"status": "BLOCKED", "reason": "profile passed locally; target hardware not physically certified"}
	return {"status": "PASS", "reason": "profile passed on declared certified target hardware"}
