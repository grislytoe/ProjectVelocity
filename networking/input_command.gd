class_name InputCommand
extends RefCounted
## Immutable by convention; no actor identity or transform is accepted from a guest.

var sequence: int = 0
var tick: int = 0
var generation: int = 0
var frame := InputFrame.new()

func values() -> Array:
	return [sequence, tick, frame.movement.x, frame.movement.y,
		frame.dash_direction.x, frame.dash_direction.y, frame.jump_pressed,
		frame.jump_held, frame.jump_released, frame.dash_pressed, generation]

static func decode(value: Variant) -> InputCommand:
	if not value is Array or value.size() != 11:
		return null
	if not NetPacket.integer(value[0], 0, 65535) or not NetPacket.integer(value[1], 0, 2147483647):
		return null
	if not NetPacket.integer(value[10], 0, 2147483647):
		return null
	for i: int in range(2, 6):
		if not NetPacket.number(value[i], 1.0):
			return null
	for i: int in range(6, 10):
		if not value[i] is bool:
			return null
	var command := InputCommand.new()
	command.sequence = int(value[0])
	command.tick = int(value[1])
	command.generation = int(value[10])
	command.frame.movement = Vector2(value[2], value[3])
	command.frame.dash_direction = Vector2(value[4], value[5])
	if command.frame.movement.length() > 1.001:
		return null
	var direction: Vector2 = command.frame.dash_direction
	if not direction.is_zero_approx() and direction.distance_to(InputLayer.quantize_dash(direction)) > 0.001:
		return null
	command.frame.jump_pressed = value[6]
	command.frame.jump_held = value[7]
	command.frame.jump_released = value[8]
	command.frame.dash_pressed = value[9]
	if command.frame.jump_pressed and command.frame.jump_released:
		return null
	return command
