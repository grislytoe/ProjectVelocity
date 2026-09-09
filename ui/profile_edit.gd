class_name ProfileEdit
extends RefCounted
## A detached draft; commit touches only owned fields in the latest save document.

var draft: Dictionary
var store: SaveStore

func _init(save_store: SaveStore) -> void:
	store = save_store
	draft = store.data.profile.duplicate(true)

func commit(complete_onboarding: bool = false) -> bool:
	if not PlayerProfileData.validate(draft):
		return false
	var previous: Dictionary = store.data.duplicate(true)
	for field: String in ["nickname", "body_color", "accent_color", "language"]:
		store.data.profile[field] = draft[field]
	if complete_onboarding:
		store.data.onboarding_complete = true
	if not store.save():
		store.data = previous
		return false
	return true
