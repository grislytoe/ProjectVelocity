class_name CheckpointProgress
extends RefCounted
## One instance per player. Course IDs are ordered; mandatory IDs must be a subset.

var ordered_ids: Array[StringName] = []
var mandatory_ids: Array[StringName] = []
var strict_order: bool = true
var reached: Array[StringName] = []


func configure(ids: Array[StringName], mandatory: Array[StringName], strict: bool = true) -> bool:
	var unique: Dictionary = {}
	for id: StringName in ids:
		if id == &"" or unique.has(id):
			return false
		unique[id] = true
	for id: StringName in mandatory:
		if not unique.has(id):
			return false
	ordered_ids = ids.duplicate()
	mandatory_ids = mandatory.duplicate()
	strict_order = strict
	reached.clear()
	return true


func can_activate(id: StringName) -> bool:
	if id not in ordered_ids or id in reached:
		return false
	return not strict_order or ordered_ids.find(id) == reached.size()


func activate(id: StringName) -> bool:
	if not can_activate(id):
		return false
	reached.append(id)
	return true


func can_finish() -> bool:
	for id: StringName in mandatory_ids:
		if id not in reached:
			return false
	return true
