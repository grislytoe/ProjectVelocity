class_name PacketFragments
extends RefCounted
## Local adapter framing; bounded incomplete messages expire without reaching the codec.

const MAGIC: int = 0x50564e32
const HEADER: int = 16
const CHUNK: int = 1000
var next_id: int = 0
var limit: int = 65536
var pending: Dictionary = {}
var completed: Dictionary = {}
var rejected: int = 0

func split(bytes: PackedByteArray) -> Array[PackedByteArray]:
	var result: Array[PackedByteArray] = []
	if bytes.is_empty() or bytes.size() > limit:
		return result
	next_id = (next_id + 1) & 0xffffffff
	var count: int = ceili(bytes.size() / float(CHUNK))
	for i: int in count:
		var packet := PackedByteArray()
		packet.resize(HEADER)
		packet.encode_u32(0, MAGIC)
		packet.encode_u32(4, next_id)
		packet.encode_u16(8, i)
		packet.encode_u16(10, count)
		packet.encode_u32(12, bytes.size())
		packet.append_array(bytes.slice(i * CHUNK, mini(bytes.size(), (i + 1) * CHUNK)))
		result.append(packet)
	return result

func prune(tick: int) -> void:
	for id: Variant in pending.keys():
		if tick - int(pending[id].tick) > 60:
			pending.erase(id)
	for id: Variant in completed.keys():
		if tick - int(completed[id]) > 120:
			completed.erase(id)

func join(packet: PackedByteArray, tick: int) -> PackedByteArray:
	prune(tick)
	if packet.size() <= HEADER or packet.size() > HEADER + CHUNK or packet.decode_u32(0) != MAGIC:
		rejected += 1
		return PackedByteArray()
	var id: int = packet.decode_u32(4)
	var index: int = packet.decode_u16(8)
	var count: int = packet.decode_u16(10)
	var size: int = packet.decode_u32(12)
	if size < 1 or size > limit or count != ceili(size / float(CHUNK)) or index >= count \
		or packet.size() - HEADER != mini(CHUNK, size - index * CHUNK):
		rejected += 1
		return PackedByteArray()
	if completed.has(id):
		return PackedByteArray()
	if not pending.has(id):
		if pending.size() >= 32:
			rejected += 1
			return PackedByteArray()
		pending[id] = {"tick": tick, "size": size, "count": count, "parts": {}}
	var item: Dictionary = pending[id]
	if item.size != size or item.count != count:
		rejected += 1
		return PackedByteArray()
	item.parts[index] = packet.slice(HEADER)
	if item.parts.size() != count:
		return PackedByteArray()
	var bytes := PackedByteArray()
	for i: int in count:
		bytes.append_array(item.parts[i])
	pending.erase(id)
	completed[id] = tick
	while completed.size() > 128:
		completed.erase(completed.keys()[0])
	return bytes

func clear() -> void:
	pending.clear()
	completed.clear()
