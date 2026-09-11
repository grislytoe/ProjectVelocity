class_name CommandQueue
extends RefCounted
## One simulated command maximum per host tick, including after bursts or replay attempts.

var config := NetworkConfig.new()
var pending: Array[InputCommand] = []
var ack: int = 65535
var last_received: int = 65535
var window_tick: int = 0
var received: int = 0
var rejected: int = 0

func accept(command: InputCommand, host_tick: int, service_tick: int) -> bool:
	if service_tick - window_tick >= 60:
		window_tick = service_tick
		received = 0
	received += 1
	var distance: int = (command.sequence - last_received) & NetSequence.MASK
	if received > config.commands_per_second or pending.size() >= config.command_queue_limit \
		or not NetSequence.newer(command.sequence, last_received) or distance > config.history_limit \
		or command.tick > host_tick + config.future_ticks or command.tick < host_tick - config.stale_ticks:
		rejected += 1
		return false
	last_received = command.sequence
	pending.append(command)
	return true

func consume() -> InputFrame:
	if pending.is_empty():
		# No held movement or repeated jump/dash on missing input.
		return InputFrame.new()
	var command: InputCommand = pending.pop_front()
	ack = command.sequence
	return command.frame

func clear() -> void:
	pending.clear()
	ack = 65535
	last_received = 65535
	received = 0
