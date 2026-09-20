class_name LobbyClipboard
extends RefCounted
## Copy only canonical public codes. Never reads clipboard contents.

func copy_code(code: String) -> bool:
	if code.is_empty() or JoinCode.normalize(code) != code or \
		not DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		return false
	DisplayServer.clipboard_set(code)
	return true
