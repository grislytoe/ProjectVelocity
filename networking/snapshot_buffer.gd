class_name SnapshotBuffer
extends RefCounted

var config := NetworkConfig.new()
var samples: Array[Dictionary] = []
var epoch: int = -1

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

func sample(time: float) -> Dictionary:
	if samples.is_empty():
		return {}
	var left: Dictionary = samples[0]
	for right: Dictionary in samples:
		if right.tick > time:
			var weight: float = clampf((time - left.tick) / maxf(1, right.tick - left.tick), 0, 1)
			return {"position": left.state.position.lerp(right.state.position, weight), "state": left.state}
		left = right
	var state: ActorState = left.state
	var velocity := Vector2(state.motor_values[0][0], state.motor_values[0][1])
	var extra: float = clampf(time - left.tick, 0, config.extrapolation_ticks)
	if state.blocked or state.state in [7, 8, 9]:
		extra = 0
	return {"position": state.position + velocity * extra / 60.0, "state": state}

func clear() -> void:
	samples.clear()
	epoch = -1
