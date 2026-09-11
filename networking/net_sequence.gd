class_name NetSequence
extends RefCounted

const MASK: int = 65535

static func newer(value: int, previous: int) -> bool:
	var distance: int = (value - previous) & MASK
	return distance > 0 and distance < 32768

static func next(value: int) -> int:
	return (value + 1) & MASK
