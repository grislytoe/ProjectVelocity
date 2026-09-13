class_name PredictionHistory
extends RefCounted

var config := NetworkConfig.new()
var commands: Array[InputCommand] = []
var states: Array[ActorState] = []
var epoch: int = -1
var corrections: int = 0
var hard_snaps: int = 0
var last_error: float = 0
var maximum_error: float = 0
var overflowed: bool = false
var metrics := NetworkTelemetry.new()
var lifecycle_rebases: int = 0
var injected_corrections: int = 0
var injected_pending: bool = false
var ordinary_corrections: int = 0
var ordinary_hard_snaps: int = 0
var replayed_commands: int = 0
var history_high_water: int = 0
var reconciliations: int = 0
var overflow_rebases: int = 0

func record(command: InputCommand, actor: PlayerController) -> void:
	commands.append(command)
	history_high_water = maxi(history_high_water, mini(commands.size(), config.history_limit))
	states.append(ActorState.capture(actor, epoch))
	if commands.size() > config.history_limit:
		commands.pop_front()
		states.pop_front()
		overflowed = true

func reconcile(authority: ActorState, ack: int, actor: PlayerController) -> void:
	var previous: Vector2 = actor.position
	var epoch_changed: bool = epoch != authority.epoch
	var lifecycle: bool = epoch_changed or authority.blocked
	var history_overflow: bool = overflowed
	var moving: bool = actor.motor.velocity.length() > 1
	reconciliations += 1
	last_error = previous.distance_to(authority.position)
	for i: int in commands.size():
		if commands[i].sequence == ack:
			last_error = states[i].position.distance_to(authority.position)
			break
	while not commands.is_empty() and not NetSequence.newer(commands[0].sequence, ack):
		commands.pop_front()
		states.pop_front()
	if epoch_changed or overflowed or authority.blocked:
		clear()
	epoch = authority.epoch
	metrics.add("ack_lag_commands", commands.size())
	replayed_commands += commands.size()
	authority.restore(actor)
	actor.replaying = true
	for i: int in commands.size():
		actor.advance(commands[i].frame)
		states[i] = ActorState.capture(actor, epoch)
	actor.replaying = false
	# Include divergence injected after the last history sample, not only ack-state error.
	last_error = maxf(last_error, previous.distance_to(actor.position))
	maximum_error = maxf(maximum_error, last_error)
	if history_overflow:
		overflow_rebases += 1
	elif lifecycle:
		lifecycle_rebases += 1
	elif injected_pending:
		injected_corrections += 1
	else:
		metrics.add("ordinary_error_px", last_error)
		if moving: metrics.add("moving_error_px", last_error)
		if last_error > config.correction_epsilon: ordinary_corrections += 1
		if last_error >= config.hard_correction: ordinary_hard_snaps += 1
	injected_pending = false
	if last_error > config.correction_epsilon:
		corrections += 1
	if epoch_changed or last_error >= config.hard_correction:
		hard_snaps += 1
		actor.presentation.position = Vector2.ZERO
		actor.clear_selection()
		actor.reset_physics_interpolation()
		actor.relocated.emit(actor.global_position)
	else:
		# Collision body is corrected immediately. Only its visual offset decays.
		actor.presentation.position += previous - actor.position
	actor.publish_visuals()

func clear() -> void:
	commands.clear()
	states.clear()
	overflowed = false
