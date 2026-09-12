class_name NetworkEmulator
extends MultiplayerTransport
## Fixed-service-tick scheduler; fractional error diffusion retains the exact mean ms.

const QUEUE_CAP: int = 256
const EXPIRY_TICKS: int = 240
var inner: MultiplayerTransport
var profile := NetworkConditionProfile.new()
var loss: float = 0
var disconnect_at: int = -1
var dropped: int = 0
var delivered: int = 0
var rng := RandomNumberGenerator.new()
var outbound_rng := RandomNumberGenerator.new()
var pending: Array[Dictionary] = []
var counters: Dictionary = {}
var queue_high_water: int = 0
var delay_ticks_total: int = 0
var delay_samples: int = 0
var schedule_hash: int = 17
var _fraction: float = 0
var _ordinal: int = 0
var _closed: bool = false

func configure(name_value: String, seed_value: int) -> bool:
	return apply_profile(NetworkConditionProfile.preset(name_value, seed_value))

func apply_profile(value: NetworkConditionProfile) -> bool:
	if not OS.is_debug_build() or not value.valid():
		return false
	# Pending messages retain their original due times; authority is never reset.
	profile = value.copy()
	rng.seed = profile.seed_value
	outbound_rng.seed = profile.seed_value ^ 0x5a17
	loss = profile.inbound_loss
	disconnect_at = profile.disconnect_tick
	_fraction = 0
	return true

func count_packet(direction: String, kind: int, action: String) -> void:
	var key: String = "%s/%s/%s" % [direction, NetPacket.Kind.keys()[kind], action]
	counters[key] = int(counters.get(key, 0)) + 1

func quantize_ms(milliseconds: float) -> int:
	var exact: float = milliseconds * 60.0 / 1000.0 + _fraction
	var ticks: int = floori(exact + 0.000000001)
	_fraction = exact - ticks
	return ticks

func trace(kind: int, delay: int, decision: int) -> void:
	# Decisions only, excluding wall time, session IDs and arrival times.
	schedule_hash = (schedule_hash * 31 + kind * 7 + delay * 3 + decision) % 2147483647

func enqueue(packet: NetPacket, time: int) -> void:
	count_packet("in", packet.kind, "sent")
	if _closed or rng.randf() < loss or pending.size() >= QUEUE_CAP:
		dropped += 1
		count_packet("in", packet.kind, "dropped")
		trace(packet.kind, 0, 1)
		return
	var jitter_value: float = rng.randf_range(-profile.jitter_ms, profile.jitter_ms)
	if profile.jitter_distribution == "triangular":
		jitter_value = (jitter_value + rng.randf_range(-profile.jitter_ms, profile.jitter_ms)) / 2
	var delay_ms: float = maxf(0, profile.one_way_ms + jitter_value)
	var reordered: bool = rng.randf() < profile.reorder_probability
	if reordered:
		delay_ms += profile.reorder_ms
		count_packet("in", packet.kind, "reordered")
	var delay: int = quantize_ms(delay_ms)
	delay_samples += 1
	delay_ticks_total += delay
	_ordinal += 1
	pending.append({"due": time + delay, "born": time, "order": _ordinal, "packet": packet})
	trace(packet.kind, delay, 2 if reordered else 0)
	if rng.randf() < profile.duplication and pending.size() < QUEUE_CAP:
		_ordinal += 1
		pending.append({"due": time + delay + 1, "born": time, "order": _ordinal, "packet": packet})
		count_packet("in", packet.kind, "duplicated")
		trace(packet.kind, delay + 1, 3)
	queue_high_water = maxi(queue_high_water, pending.size())

func poll(time: int) -> Array[NetPacket]:
	if inner != null:
		for packet: NetPacket in inner.poll(time):
			enqueue(packet, time)
		connected = inner.connected
		rejected = inner.rejected
		error = inner.error
	if disconnect_at >= 0 and time >= disconnect_at:
		disconnect_at = -1
		close()
	var result: Array[NetPacket] = []
	pending.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.order < b.order if a.due == b.due else a.due < b.due)
	for i: int in range(pending.size() - 1, -1, -1):
		var item: Dictionary = pending[i]
		if time - int(item.born) > EXPIRY_TICKS:
			dropped += 1
			count_packet("in", item.packet.kind, "expired")
			pending.remove_at(i)
		elif item.due <= time:
			result.push_front(item.packet)
			pending.remove_at(i)
			delivered += 1
			count_packet("in", item.packet.kind, "delivered")
	return result

func send(packet: NetPacket) -> void:
	count_packet("out", packet.kind, "sent")
	if _closed or outbound_rng.randf() < profile.outbound_loss:
		count_packet("out", packet.kind, "dropped")
		return
	if inner != null:
		inner.send(packet)
		count_packet("out", packet.kind, "delivered")

func reopen() -> void:
	_closed = false

func close() -> void:
	if inner != null:
		inner.close()
	for item: Dictionary in pending:
		count_packet("in", item.packet.kind, "teardown_dropped")
		dropped += 1
	pending.clear()
	connected = false
	_closed = true

func report() -> Dictionary:
	return {"profile": profile.values(), "packets": counters.duplicate(), "queue": pending.size(),
		"queue_high_water": queue_high_water, "queue_cap": QUEUE_CAP,
		"schedule_digest": schedule_hash, "delay_samples": delay_samples,
		"effective_simulated_one_way_ms": delay_ticks_total * 1000.0 / (60 * maxi(1, delay_samples))}
