class_name SnapshotBuffer
extends RefCounted

var config := NetworkConfig.new()
var samples: Array[Dictionary] = []
var epoch: int = -1
var underflow: int = 0
var extrapolated: int = 0
var held: int = 0
var interpolated: int = 0
var high_water: int = 0

func insert(tick: int, state: ActorState) -> void:
	if epoch > state.epoch:
		return
	if epoch != state.epoch:
		samples.clear()
		epoch = state.epoch
	for sample: Dictionary in samples:
		if sample.tick == tick:
			return
	samples.append({"tick": tick, "state": state})
	samples.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.tick < b.tick)
	while samples.size() > config.buffer_limit:
		samples.pop_front()
	high_water = maxi(high_water, samples.size())

func sample(time: float) -> Dictionary:
	if samples.is_empty():
		underflow += 1
		return {}
	var left: Dictionary = samples[0]
	for right: Dictionary in samples:
		if right.tick > time:
			if time < float(samples[0].tick): underflow += 1
			else: interpolated += 1
			var weight: float = clampf((time - left.tick) / maxf(1, right.tick - left.tick), 0, 1)
			return {"position": left.state.position.lerp(right.state.position, weight), "state": left.state}
		left = right
	var state: ActorState = left.state
	var velocity := Vector2(state.motor_values[0][0], state.motor_values[0][1])
	if time - left.tick > config.extrapolation_ticks or state.blocked or state.state in [7, 8, 9]: held += 1
	else: extrapolated += 1
	var extra: float = clampf(time - left.tick, 0, config.extrapolation_ticks)
	if state.blocked or state.state in [7, 8, 9]:
		extra = 0
	return {"position": state.position + velocity * extra / 60.0, "state": state}

func clear() -> void:
	samples.clear()
	epoch = -1
