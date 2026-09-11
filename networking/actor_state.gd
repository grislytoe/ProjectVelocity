class_name ActorState
extends RefCounted
## Complete motor rollback state; collision contacts are resampled against the current world.

const FIELDS: Array[String] = ["velocity", "double_jump_available", "dash_available",
	"dash_vector", "coyote_ticks", "wall_lock_ticks", "dash_ticks", "end_lag_ticks",
	"invulnerability_ticks", "tick_count", "events", "requested_horizontal", "wall_side",
	"_was_grounded", "_surface_contacts", "_spent_contacts"]
var position: Vector2
var state: int = 0
var epoch: int = 0
var blocked: bool = true
var motor_values: Array = []

static func capture(actor: PlayerController, generation: int = 0) -> ActorState:
	var result := ActorState.new()
	result.position = actor.position
	result.state = actor.motor.machine.current
	result.epoch = generation
	result.blocked = actor.start_blocked
	for field: String in FIELDS:
		var value: Variant = actor.motor.get(field)
		result.motor_values.append([value.x, value.y] if value is Vector2 else value)
	return result

func restore(actor: PlayerController) -> void:
	actor.position = position
	actor.start_blocked = blocked
	for i: int in FIELDS.size():
		var value: Variant = motor_values[i]
		actor.motor.set(FIELDS[i], Vector2(value[0], value[1]) if value is Array else value)
	actor.motor.machine.current = state as PlayerStateMachine.State
	actor.velocity = actor.motor.velocity
	actor.contacts.clear()
	actor.invalidate_collision_cache()

func values() -> Array:
	return [position.x, position.y, state, epoch, blocked, motor_values]

static func decode(value: Variant) -> ActorState:
	if not value is Array or value.size() != 6 or not NetPacket.number(value[0], 1000000) \
		or not NetPacket.number(value[1], 1000000) or not NetPacket.integer(value[2], 0, 9) \
		or not NetPacket.integer(value[3], 0, 2147483647) or not value[4] is bool \
		or not value[5] is Array or value[5].size() != FIELDS.size():
		return null
	var data: Array = value[5]
	for i: int in data.size():
		if i in [0, 3]:
			if not NetPacket.vector(data[i], 10000 if i == 0 else 1):
				return null
		elif i in [1, 2, 13]:
			if not data[i] is bool:
				return null
		elif i in [11, 12]:
			if not NetPacket.number(data[i], 1):
				return null
		else:
			var limit: int = 2147483647 if i == 9 else 65535
			if i in [14, 15]: limit = 7
			if i == 10: limit = 63
			if not NetPacket.integer(data[i], 0, limit):
				return null
	var result := ActorState.new()
	result.position = Vector2(value[0], value[1])
	result.state = int(value[2])
	result.epoch = int(value[3])
	result.blocked = value[4]
	result.motor_values = data.duplicate(true)
	return result

func visual(events: int = 0) -> PlayerVisualFrame:
	var frame := PlayerVisualFrame.new()
	frame.state = state as PlayerStateMachine.State
	frame.velocity = Vector2(motor_values[0][0], motor_values[0][1])
	frame.dash_vector = Vector2(motor_values[3][0], motor_values[3][1])
	frame.requested_horizontal = motor_values[11]
	frame.wall_side = motor_values[12]
	frame.speed_ratio = absf(frame.velocity.x) / 680.0
	frame.jump_ready = motor_values[1]
	frame.dash_ready = motor_values[2]
	frame.invulnerable = motor_values[8] > 0
	frame.events = events
	return frame
