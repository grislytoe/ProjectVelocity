class_name NetworkConditionProfile
extends RefCounted
## Application-message shaping, inbound once per endpoint. Rates are probabilities.

const NAMES: Array[String] = ["clean", "rtt80", "rtt150", "rtt200", "rtt250", "combined", "wan", "stress"]
var id: String = "clean"
var one_way_ms: float = 0
var jitter_ms: float = 0
var jitter_distribution: String = "uniform"
var inbound_loss: float = 0
var outbound_loss: float = 0
var duplication: float = 0
var reorder_probability: float = 0
var reorder_ms: float = 1000.0 / 15.0
var seed_value: int = 15
var disconnect_tick: int = -1
var reconnect_after_ticks: int = 45

func valid() -> bool:
	return id in NAMES and is_finite(one_way_ms) and one_way_ms >= 0 and one_way_ms <= 1000 \
		and is_finite(jitter_ms) and jitter_ms >= 0 and jitter_ms <= 1000 \
		and jitter_distribution in ["uniform", "triangular"] \
		and probability(inbound_loss) and probability(outbound_loss) and probability(duplication) \
		and probability(reorder_probability) and is_finite(reorder_ms) and reorder_ms >= 0 \
		and reorder_ms <= 1000 and seed_value >= 0 and seed_value <= 2147483647 \
		and disconnect_tick >= -1 and disconnect_tick <= 2147480947 \
		and reconnect_after_ticks >= 1 and reconnect_after_ticks <= 2700

static func probability(value: float) -> bool:
	return is_finite(value) and value >= 0 and value <= 1

func values() -> Dictionary:
	return {"id": id, "simulated_one_way_ms": one_way_ms, "simulated_rtt_ms": one_way_ms * 2,
		"jitter_distribution": jitter_distribution, "jitter_range_ms": [-jitter_ms, jitter_ms],
		"inbound_loss": inbound_loss, "outbound_loss": outbound_loss,
		"duplication": duplication, "reorder_probability": reorder_probability,
		"reorder_ms": reorder_ms, "seed": seed_value, "disconnect_tick": disconnect_tick,
		"reconnect_after_ticks": reconnect_after_ticks}

func copy() -> NetworkConditionProfile:
	var result := NetworkConditionProfile.new()
	for key: String in ["id", "one_way_ms", "jitter_ms", "jitter_distribution", "inbound_loss",
		"outbound_loss", "duplication", "reorder_probability", "reorder_ms", "seed_value",
		"disconnect_tick", "reconnect_after_ticks"]:
		result.set(key, get(key))
	return result

static func from_dictionary(data: Dictionary) -> NetworkConditionProfile:
	var result := NetworkConditionProfile.new()
	var numeric: Array[String] = ["one_way_ms", "jitter_ms", "inbound_loss", "outbound_loss",
		"duplication", "reorder_probability", "reorder_ms"]
	var integers: Array[String] = ["seed_value", "disconnect_tick", "reconnect_after_ticks"]
	for key: Variant in data:
		if not key is String: return null
		var value: Variant = data[key]
		if key in numeric:
			if not NetPacket.number(value, 10000): return null
		elif key in integers:
			if not NetPacket.integer(value, -1, 2147483647): return null
		elif key in ["id", "jitter_distribution"]:
			if not value is String: return null
		else:
			return null
		result.set(key, value)
	return result if result.valid() else null

static func preset(name_value: String, seed_input: int = 15) -> NetworkConditionProfile:
	var result := NetworkConditionProfile.new()
	result.id = name_value
	result.seed_value = seed_input
	match name_value:
		"rtt80": result.one_way_ms = 40
		"rtt150": result.one_way_ms = 75
		"rtt200": result.one_way_ms = 100
		"rtt250": result.one_way_ms = 125
		"combined":
			result.one_way_ms = 75
			result.jitter_ms = 25
			result.inbound_loss = 0.05
			result.outbound_loss = 0.02
			result.duplication = 0.03
			result.reorder_probability = 0.15
		"wan", "stress":
			result.one_way_ms = (4 if name_value == "wan" else 6) * 1000.0 / 60
			result.jitter_ms = (2 if name_value == "wan" else 3) * 1000.0 / 60
			result.inbound_loss = 0.05 if name_value == "wan" else 0.10
			result.duplication = 0.03 if name_value == "wan" else 0.10
			result.reorder_probability = 0.15 if name_value == "wan" else 0.20
	return result
