class_name NetworkTelemetry
extends RefCounted
## Dev-only observer. Session counters, rolling 300 samples, 120 seconds of 1 Hz traces.

const SCHEMA: int = 1
const SAMPLE_CAP: int = 300
const TRACE_CAP: int = 120
var samples: Dictionary = {}
var peaks: Dictionary = {}
var trace_rows: Array[Dictionary] = []
var ticks: int = 0
var round_id: int = 0
var resets: int = 0
var warning: bool = false
var warning_ticks: int = 0
var warning_entries: int = 0
var _bad_ticks: int = 0
var _good_ticks: int = 0
var disconnect_ticks: int = 0
var disconnects: int = 0
var _was_disconnected: bool = false
var motion_trace: Array[Dictionary] = []
var _previous_remote := Vector2.ZERO
var _previous_epoch: int = -1
var _ever_joined: bool = false
var _recovery_tick: int = -1
var _recovery_usec: int = 0
var reconnects_completed: int = 0

func add(name_value: String, value: float) -> void:
	if not is_finite(value): return
	if not samples.has(name_value): samples[name_value] = []
	var rows: Array = samples[name_value]
	rows.append(value)
	if rows.size() > SAMPLE_CAP: rows.pop_front()
	peaks[name_value] = maxf(float(peaks.get(name_value, value)), value)

func metric(name_value: String) -> Dictionary:
	var values: Array = samples.get(name_value, [])
	if values.is_empty(): return {"count": 0, "current": 0, "peak": 0, "p50": 0, "p95": 0, "p99": 0}
	var ordered: Array = values.duplicate()
	ordered.sort()
	return {"count": values.size(), "current": values.back(), "peak": peaks[name_value],
		"p50": ordered[ceili(ordered.size() * 0.50) - 1],
		"p95": ordered[ceili(ordered.size() * 0.95) - 1],
		"p99": ordered[ceili(ordered.size() * 0.99) - 1]}

func update_warning(rtt_ms: float, fresh: bool = true) -> void:
	if not fresh: return
	_bad_ticks = _bad_ticks + 1 if rtt_ms > 200 else 0
	_good_ticks = _good_ticks + 1 if rtt_ms <= 180 else 0
	if not warning and _bad_ticks >= 30:
		warning = true
		warning_entries += 1
	if warning and _good_ticks >= 60: warning = false
	if warning: warning_ticks += 1

static func band(rtt_ms: float) -> String:
	if rtt_ms <= 80: return "near_ideal"
	if rtt_ms <= 150: return "comfortable"
	if rtt_ms <= 200: return "playable"
	return "warning"

func reset_window(new_round: int) -> void:
	samples.clear()
	peaks.clear()
	trace_rows.clear()
	motion_trace.clear()
	round_id = new_round
	resets += 1

func observe_connection(joined: bool, tick: int, usec: int) -> void:
	if joined:
		if _recovery_tick >= 0:
			add("reconnect_service_ms", (tick - _recovery_tick) * 1000.0 / 60)
			add("reconnect_wall_ms", (usec - _recovery_usec) / 1000.0)
			reconnects_completed += 1
			_recovery_tick = -1
		_ever_joined = true
	elif _ever_joined and _recovery_tick < 0:
		_recovery_tick = tick
		_recovery_usec = usec

func observe(session: NetworkSession) -> void:
	if not OS.is_debug_build(): return
	ticks += 1
	observe_connection(session.joined, session.service_tick, Time.get_ticks_usec())
	if round_id != session.round_id: reset_window(session.round_id)
	var rtt: float = session.measured_rtt_ms
	update_warning(rtt, session.joined and session.service_tick - session.last_pong_service <= 120)
	if session.last_pong_service == session.service_tick:
		add("measured_rtt_ms", rtt)
		add("service_clock_rtt_ms", session.rtt_ticks * 1000.0 / 60)
	var disconnected_now: bool = session.paused or session.ended
	if disconnected_now:
		disconnect_ticks += 1
		if not _was_disconnected: disconnects += 1
	_was_disconnected = disconnected_now
	add("history_depth", session.prediction.commands.size())
	add("interpolation_depth", session.remote_buffer_depth())
	add("queue_depth", (session.transport as NetworkEmulator).pending.size())
	if session.joined and not session.host:
		add("snapshot_age_service_ms", (session.service_tick - session.last_snapshot_service) * 1000.0 / 60)
	var remote_position: Vector2 = session.course.remote.position + session.course.remote.presentation.position
	var remote_epoch: int = session.epochs[1] if session.host else session.interpolation.epoch
	if session.joined and session.phase() == RaceBaseline.Phase.RUNNING and remote_epoch == _previous_epoch:
		add("remote_step_px", remote_position.distance_to(_previous_remote))
		motion_trace.append({"tick": session.service_tick, "x": remote_position.x, "y": remote_position.y})
		if motion_trace.size() > SAMPLE_CAP: motion_trace.pop_front()
	_previous_remote = remote_position
	_previous_epoch = remote_epoch
	if session.service_tick % 60 == 0:
		var actor: PlayerController = session.course.actors[0 if session.host else 1]
		trace_rows.append({"service_tick": session.service_tick, "clock": session.clock_ticks,
			"rtt_ms": rtt, "error_px": session.prediction.last_error, "history": session.prediction.commands.size(),
			"remote_x": session.course.remote.position.x, "remote_y": session.course.remote.position.y,
			"local_x": actor.position.x, "local_y": actor.position.y, "warning": warning})
		if trace_rows.size() > TRACE_CAP: trace_rows.pop_front()

func report() -> Dictionary:
	var metrics: Dictionary = {}
	for key: String in samples: metrics[key] = metric(key)
	return {"schema": SCHEMA, "round": round_id, "window_resets": resets,
		"sample_cap": SAMPLE_CAP, "sample_policy": "last 300 per metric; peaks since round/window reset",
		"motion_trace_60hz": motion_trace.duplicate(true), "session_service_ticks": ticks, "metrics": metrics, "trace_1hz": trace_rows.duplicate(true),
		"warning": warning, "warning_ticks": warning_ticks, "warning_entries": warning_entries,
		"reconnects_completed": reconnects_completed, "disconnects": disconnects, "disconnect_duration_ms": disconnect_ticks * 1000.0 / 60}
