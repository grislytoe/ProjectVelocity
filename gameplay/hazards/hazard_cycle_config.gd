class_name HazardCycleConfig
extends Resource
## Seconds are rounded upward to fixed 60 Hz ticks. Immutable after scene entry.

@export var size: Vector2 = Vector2(100, 24)
@export_range(0.0, 60.0) var inactive_duration: float = 1.5
@export_range(0.017, 10.0) var telegraph_duration: float = 0.5
@export_range(0.017, 60.0) var active_duration: float = 1.0
@export_range(0.0, 120.0) var phase_offset: float = 0.0


func validate() -> bool:
	return size.is_finite() and size.x > 0 and size.y > 0 \
		and is_finite(inactive_duration) and inactive_duration >= 0 \
		and is_finite(telegraph_duration) and telegraph_duration > 0 \
		and is_finite(active_duration) and active_duration > 0 \
		and is_finite(phase_offset) and phase_offset >= 0
