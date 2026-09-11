class_name NetworkConfig
extends Resource
## M15 defaults where the master leaves policy configurable. All durations are ticks.

@export var physics_hz: int = 60
@export var input_hz: int = 60
@export var snapshot_hz: int = 20
@export var interpolation_ticks: int = 6
@export var extrapolation_ticks: int = 3
@export var history_limit: int = 240
@export var buffer_limit: int = 32
@export var command_queue_limit: int = 12
@export var stale_ticks: int = 120
@export var future_ticks: int = 30
@export var commands_per_second: int = 90
@export var correction_epsilon: float = 0.5
@export var hard_correction: float = 96.0
@export var smoothing_ticks: int = 6
@export var timeout_ticks: int = 180
@export var reconnect_ticks: int = 2700
@export var countdown_ticks: int = 180
@export var hint_ticks: int = 180
@export var event_lifetime: int = 120
@export var max_packet_bytes: int = 65536
@export var protocol: int = BuildInfo.NETWORK_PROTOCOL_VERSION

func valid() -> bool:
	return physics_hz == 60 and input_hz == 60 and snapshot_hz in [20, 30] \
		and interpolation_ticks >= 0 and interpolation_ticks <= 30 \
		and extrapolation_ticks in range(0, 7) and history_limit >= 120 and history_limit <= 600 \
		and buffer_limit >= 4 and buffer_limit <= 64 and command_queue_limit in range(1, 31) \
		and correction_epsilon > 0 and hard_correction > correction_epsilon \
		and smoothing_ticks > 0 and timeout_ticks >= 60 and reconnect_ticks == 2700 \
		and stale_ticks >= 0 and future_ticks >= 0 and commands_per_second >= input_hz \
		and countdown_ticks > 0 and hint_ticks >= 0 and event_lifetime >= 60 \
		and max_packet_bytes >= 4096 and max_packet_bytes <= 65536
