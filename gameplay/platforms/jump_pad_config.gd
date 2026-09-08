class_name JumpPadConfig
extends PlatformConfig

@export var direction: Vector2 = Vector2.UP
@export_range(1.0, 4000.0) var force: float = 1200.0


func validate() -> bool:
	return super.validate() and direction.is_finite() and not direction.is_zero_approx() \
		and is_finite(force) and force > 0
