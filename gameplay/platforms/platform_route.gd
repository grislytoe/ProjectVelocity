class_name PlatformRoute
extends RefCounted
## Absolute fixed-tick sampling: no accumulating drift or render-time dependency.

var _from: Array[Vector2] = []
var _to: Array[Vector2] = []
var _duration: Array[int] = []
var total_ticks: int = 0
var _loop: bool
var _end: Vector2


func _init(config: MovingPlatformConfig) -> void:
	_loop = config.loop
	var order: Array[int] = []
	for index: int in config.route.size():
		order.append(config.route.size() - 1 - index if config.reverse else index)
	if config.loop:
		if config.ping_pong:
			for index: int in range(order.size() - 2, 0, -1):
				order.append(order[index])
		order.append(order[0])
	for index: int in order.size():
		var point: Vector2 = config.route[order[index]]
		if index == order.size() - 1 and config.loop:
			break
		var wait: float = 0 if config.waits.is_empty() else config.waits[order[index]]
		_append(point, point, PlayerMovementConfig.ticks(wait))
		if index + 1 < order.size():
			var target: Vector2 = config.route[order[index + 1]]
			_append(point, target, maxi(1, ceili(point.distance_to(target) / config.speed * 60)))
	_end = config.route[order[-1]]


func _append(from: Vector2, to: Vector2, duration: int) -> void:
	if duration <= 0:
		return
	_from.append(from)
	_to.append(to)
	_duration.append(duration)
	total_ticks += duration


func sample(tick: int) -> Vector2:
	var remaining: int = maxi(0, tick)
	if _loop:
		remaining %= total_ticks
	for index: int in _duration.size():
		if remaining < _duration[index]:
			return _from[index].lerp(_to[index], float(remaining) / _duration[index])
		remaining -= _duration[index]
	return _end
