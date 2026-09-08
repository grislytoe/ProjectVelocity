class_name BreakablePlatformConfig
extends PlatformConfig

@export_range(0.0, 10.0) var activation_delay: float = 0.6
@export var restores: bool = true
@export_range(0.0, 60.0) var restore_delay: float = 2.0


func validate() -> bool:
	return super.validate() and is_finite(activation_delay) and activation_delay >= 0 \
		and is_finite(restore_delay) and restore_delay >= 0
