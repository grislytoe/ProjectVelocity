class_name LaserConfig
extends HazardCycleConfig

enum Mode { PERMANENT, CYCLIC }
@export var mode: Mode = Mode.CYCLIC


func _init() -> void:
	size = Vector2(18, 240)


func validate() -> bool:
	return super.validate() and mode in Mode.values()
