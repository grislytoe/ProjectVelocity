class_name SpikeConfig
extends HazardCycleConfig

enum Mode { STATIC, TIMED, TRIGGER }
@export var mode: Mode = Mode.STATIC
@export var initially_triggered: bool = false
@export var trigger_on_player_overlap: bool = false
@export var trigger_size: Vector2 = Vector2(220, 100)
@export var trigger_offset: Vector2 = Vector2(-140, -40)


func validate() -> bool:
	return super.validate() and mode in Mode.values() and trigger_size.is_finite() \
		and trigger_size.x > 0 and trigger_size.y > 0 and trigger_offset.is_finite()
