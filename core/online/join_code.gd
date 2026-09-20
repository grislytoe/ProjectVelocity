class_name JoinCode
extends RefCounted
## M19 policy. Master specifies uppercase Latin/digits without ambiguous characters.
## Exact exclusion set is our documented convention, not an EOS uniqueness guarantee.

const ALPHABET: String = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
const LENGTH: int = 6
const MAX_ATTEMPTS: int = 8

static func normalize(value: String) -> String:
	var trimmed: String = value.strip_edges()
	for i: int in trimmed.length():
		if trimmed.unicode_at(i) > 127:
			return "" # Unicode case folding must not turn a homoglyph into an ASCII code.
	var code: String = trimmed.to_upper()
	if code.length() != LENGTH:
		return ""
	for character: String in code:
		if not ALPHABET.contains(character):
			return ""
	return code

static func generate(entropy: Callable = Callable()) -> String:
	var bytes: PackedByteArray = entropy.call(32) if entropy.is_valid() else Crypto.new().generate_random_bytes(32)
	var code: String = ""
	# Rejection sampling avoids modulo bias for the 31-character alphabet.
	var ceiling: int = 256 - (256 % ALPHABET.length())
	for value: int in bytes:
		if value < ceiling:
			code += ALPHABET[value % ALPHABET.length()]
			if code.length() == LENGTH:
				return code
	return "" # Entropy failure is explicit; never fall back to time/nickname/randf.

static func reserve_candidate(query: Callable, entropy: Callable = Callable()) -> String:
	# query returns 0 free, >0 collision, <0 service failure. Still not atomic reservation.
	for attempt: int in MAX_ATTEMPTS:
		var code: String = generate(entropy)
		if code.is_empty():
			return ""
		var count: int = int(query.call(code))
		if count < 0:
			return ""
		if count == 0:
			return code
	return ""
