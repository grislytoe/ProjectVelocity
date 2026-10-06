class_name BuildProvenance
extends Resource
## Patched only in the clean staging source snapshot; committed editor value stays UNEMBEDDED.

@export var source_sha: String = "UNEMBEDDED"


func validated_source_sha() -> String:
	var candidate: String = source_sha.to_lower()
	if candidate == "unembedded":
		return "UNEMBEDDED"
	if candidate.length() != 40:
		return "INVALID"
	for index: int in candidate.length():
		if candidate[index] not in "0123456789abcdef":
			return "INVALID"
	return candidate
