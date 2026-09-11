class_name NetworkEmulator
extends MultiplayerTransport
## Seeded inbound shaping, fixed ticks. Each endpoint shapes its incoming direction once.

var inner: MultiplayerTransport
var latency: int = 0
var jitter: int = 0
var loss: float = 0.0
var duplicate: float = 0.0
var reorder: float = 0.0
var disconnect_at: int = -1
var dropped: int = 0
var delivered: int = 0
var rng := RandomNumberGenerator.new()
var pending: Array[Dictionary] = []

func configure(profile: String, seed_value: int) -> void:
	rng.seed = seed_value
	if profile == "wan":
		latency = 4
		jitter = 2
		loss = 0.05
		duplicate = 0.03
		reorder = 0.15
	elif profile == "stress":
		latency = 6
		jitter = 3
		loss = 0.10
		duplicate = 0.10
		reorder = 0.20

func enqueue(packet: NetPacket, time: int) -> void:
	if rng.randf() < loss or pending.size() >= 256:
		dropped += 1
		return
	var delay: int = maxi(0, latency + rng.randi_range(-jitter, jitter))
	if rng.randf() < reorder:
		delay += 4
	pending.append({"due": time + delay, "packet": packet})
	if rng.randf() < duplicate and pending.size() < 256:
		pending.append({"due": time + delay + 1, "packet": packet})

func poll(time: int) -> Array[NetPacket]:
	if inner != null:
		for packet: NetPacket in inner.poll(time):
			enqueue(packet, time)
		connected = inner.connected
		rejected = inner.rejected
		error = inner.error
	if disconnect_at >= 0 and time >= disconnect_at:
		close()
	var result: Array[NetPacket] = []
	for i: int in range(pending.size() - 1, -1, -1):
		if pending[i].due <= time:
			result.push_front(pending[i].packet)
			pending.remove_at(i)
			delivered += 1
	return result

func send(packet: NetPacket) -> void:
	if inner != null:
		inner.send(packet)

func close() -> void:
	if inner != null:
		inner.close()
	pending.clear()
	connected = false
