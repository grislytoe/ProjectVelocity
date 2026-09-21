class_name OnlineSeries
extends RefCounted
## Transport-independent, host-owned race/round/series state. Presentation may observe it only.

enum Phase {
	LOBBY,
	SERIES_PREPARATION,
	SYNCHRONIZED_LOADING,
	CONTROLS_HINT,
	COUNTDOWN,
	RACING,
	FINISH_WINDOW,
	ROUND_RESULTS,
	BETWEEN_ROUND_READY,
	FINAL_SERIES_RESULTS,
	RECONNECT,
	ENDED,
}
enum FinishStatus { PENDING, FINISHED, DNF }
enum ResultReason { NORMAL, SECOND_PLAYER_TIMEOUT, GUEST_DISCONNECT_TIMEOUT }
enum Action { PLAY_AGAIN, RETURN_TO_LOBBY, MAIN_MENU }

const SECOND_PLAYER_TICKS: int = 30 * 60

var series_generation: int = 1
var round_generation: int = 1
var round_index: int = 1
var rounds_total: int = 1
var map_id: String = ""
var map_version: int = 0
var map_checksum: String = ""
var settings_identity: String = ""
var phase: Phase = Phase.SERIES_PREPARATION
var loaded: Array[bool] = [false, false]
var loaded_revisions: Array[int] = [-1, -1]
var ready: Array[bool] = [false, false]
var ready_revisions: Array[int] = [-1, -1]
var hint_end_tick: int = -1
var start_tick: int = -1
var finish_deadline: int = -1
var current_winner: int = 0
var current_finish_times: Array[int] = [-1, -1]
var current_progress: Array[int] = [0, 0]
var current_checkpoints: Array = [[], []]
var score: Array[int] = [0, 0]
var best_times: Array[int] = [-1, -1]
var round_results: Array = []
var final_winner: int = -1
var _round_recorded: bool = false
var _phase_before_reconnect: Phase = Phase.SYNCHRONIZED_LOADING

static func identity(id: String, version: int, checksum: String, rounds: int) -> String:
	return "%s|%d|%s|%d|p%d|w%d" % [id, version, checksum, rounds,
		BuildInfo.NETWORK_PROTOCOL_VERSION, BuildInfo.NETWORK_WIRE_REVISION]

func configure(definition: MapDefinition, rounds: int, generation: int = 1) -> bool:
	if definition == null or rounds < 1 or rounds > 10 or generation < 1:
		return false
	series_generation = generation
	round_generation = 1
	round_index = 1
	rounds_total = rounds
	map_id = definition.map_id
	map_version = definition.map_version
	map_checksum = definition.declared_checksum
	settings_identity = identity(map_id, map_version, map_checksum, rounds_total)
	_reset_series()
	phase = Phase.SYNCHRONIZED_LOADING
	return true

func matches_definition(definition: MapDefinition) -> bool:
	return definition != null and map_id == definition.map_id and map_version == definition.map_version \
		and map_checksum == definition.declared_checksum \
		and settings_identity == identity(map_id, map_version, map_checksum, rounds_total)

func confirm_loaded(player: int, series_id: int, round_id: int, id: String,
		version: int, checksum: String, revision: int) -> bool:
	var index: int = player - 1
	if index not in [0, 1] or phase != Phase.SYNCHRONIZED_LOADING \
		or series_id != series_generation or round_id != round_generation \
		or id != map_id or version != map_version or checksum != map_checksum \
		or revision <= loaded_revisions[index]:
		return false
	loaded_revisions[index] = revision
	loaded[index] = true
	return true

func both_loaded() -> bool:
	return loaded[0] and loaded[1]

func begin_hint(host_tick: int, duration: int) -> bool:
	if phase != Phase.SYNCHRONIZED_LOADING or not both_loaded() or duration < 0:
		return false
	phase = Phase.CONTROLS_HINT
	hint_end_tick = host_tick + duration
	return true

func begin_countdown(authoritative_start_tick: int, host_tick: int) -> bool:
	if phase != Phase.CONTROLS_HINT or host_tick < hint_end_tick or authoritative_start_tick <= host_tick:
		return false
	phase = Phase.COUNTDOWN
	start_tick = authoritative_start_tick
	return true

func begin_race(host_tick: int) -> bool:
	if phase != Phase.COUNTDOWN or host_tick < start_tick:
		return false
	phase = Phase.RACING
	return true

func record_finish(player: int, time_ticks: int, progress_value: int,
		checkpoint_indices: Array, race_clock: int) -> bool:
	var index: int = player - 1
	if index not in [0, 1] or phase not in [Phase.RACING, Phase.FINISH_WINDOW] \
		or current_finish_times[index] >= 0 or time_ticks < 0 \
		or (phase == Phase.FINISH_WINDOW and race_clock > finish_deadline):
		return false
	current_finish_times[index] = time_ticks
	current_progress[index] = progress_value
	current_checkpoints[index] = checkpoint_indices.duplicate()
	if best_times[index] < 0 or time_ticks < best_times[index]:
		best_times[index] = time_ticks
	if current_winner == 0:
		current_winner = player
		finish_deadline = race_clock + SECOND_PLAYER_TICKS
		phase = Phase.FINISH_WINDOW
	if current_finish_times[0] >= 0 and current_finish_times[1] >= 0:
		finalize_round(ResultReason.NORMAL)
	return true

func expire_finish_window(race_clock: int, progress_values: Array[int], checkpoints: Array) -> bool:
	if phase != Phase.FINISH_WINDOW or finish_deadline < 0 or race_clock < finish_deadline:
		return false
	for i: int in 2:
		if current_finish_times[i] < 0:
			current_progress[i] = progress_values[i]
			current_checkpoints[i] = checkpoints[i].duplicate()
	finalize_round(ResultReason.SECOND_PLAYER_TIMEOUT)
	return true

func award_guest_disconnect(progress_values: Array[int], checkpoints: Array) -> bool:
	if _round_recorded or phase in [Phase.ROUND_RESULTS, Phase.BETWEEN_ROUND_READY,
			Phase.FINAL_SERIES_RESULTS, Phase.LOBBY, Phase.ENDED]:
		return false
	current_winner = 1
	for i: int in 2:
		current_progress[i] = progress_values[i]
		current_checkpoints[i] = checkpoints[i].duplicate()
	finalize_round(ResultReason.GUEST_DISCONNECT_TIMEOUT)
	return true

func finalize_round(reason: ResultReason) -> bool:
	if _round_recorded or current_winner not in [1, 2]:
		return false
	_round_recorded = true
	score[current_winner - 1] += 1
	var statuses: Array[int] = [
		FinishStatus.FINISHED if current_finish_times[0] >= 0 else FinishStatus.DNF,
		FinishStatus.FINISHED if current_finish_times[1] >= 0 else FinishStatus.DNF,
	]
	round_results.append([round_index, round_generation, settings_identity, [1, 2],
		current_winner, current_finish_times.duplicate(), statuses, current_progress.duplicate(),
		[current_checkpoints[0].duplicate(), current_checkpoints[1].duplicate()],
		finish_deadline, reason])
	phase = Phase.ROUND_RESULTS
	return true

func enter_between_round() -> bool:
	if phase != Phase.ROUND_RESULTS:
		return false
	ready = [false, false]
	ready_revisions = [-1, -1]
	if round_index >= rounds_total:
		final_winner = 1 if score[0] > score[1] else (2 if score[1] > score[0] else 0)
		phase = Phase.FINAL_SERIES_RESULTS
	else:
		phase = Phase.BETWEEN_ROUND_READY
	return true

func set_ready(player: int, value: bool, series_id: int, round_id: int, revision: int) -> bool:
	var index: int = player - 1
	if index not in [0, 1] or phase != Phase.BETWEEN_ROUND_READY \
		or series_id != series_generation or round_id != round_generation \
		or revision <= ready_revisions[index]:
		return false
	ready_revisions[index] = revision
	ready[index] = value
	return true

func both_ready() -> bool:
	return phase == Phase.BETWEEN_ROUND_READY and ready[0] and ready[1]

func begin_next_round() -> bool:
	if not both_ready() or round_index >= rounds_total:
		return false
	round_index += 1
	round_generation += 1
	_reset_round()
	phase = Phase.SYNCHRONIZED_LOADING
	return true

func play_again() -> bool:
	if phase != Phase.FINAL_SERIES_RESULTS:
		return false
	series_generation += 1
	round_generation = 1
	round_index = 1
	_reset_series()
	phase = Phase.SYNCHRONIZED_LOADING
	return true

func return_to_lobby() -> bool:
	if phase not in [Phase.FINAL_SERIES_RESULTS, Phase.ROUND_RESULTS, Phase.BETWEEN_ROUND_READY]:
		return false
	phase = Phase.LOBBY
	return true

func end() -> void:
	phase = Phase.ENDED

func enter_reconnect() -> bool:
	if phase in [Phase.LOBBY, Phase.FINAL_SERIES_RESULTS, Phase.ENDED, Phase.RECONNECT]:
		return false
	_phase_before_reconnect = phase
	phase = Phase.RECONNECT
	return true

func resume_reconnect() -> bool:
	if phase != Phase.RECONNECT:
		return false
	phase = _phase_before_reconnect
	return true

func _reset_series() -> void:
	score = [0, 0]
	best_times = [-1, -1]
	round_results.clear()
	final_winner = -1
	_reset_round()

func _reset_round() -> void:
	loaded = [false, false]
	loaded_revisions = [-1, -1]
	ready = [false, false]
	ready_revisions = [-1, -1]
	hint_end_tick = -1
	start_tick = -1
	finish_deadline = -1
	current_winner = 0
	current_finish_times = [-1, -1]
	current_progress = [0, 0]
	current_checkpoints = [[], []]
	_round_recorded = false

func capture() -> Array:
	return [series_generation, round_generation, round_index, rounds_total, map_id, map_version,
		map_checksum, settings_identity, phase, loaded.duplicate(), loaded_revisions.duplicate(),
		ready.duplicate(), ready_revisions.duplicate(), hint_end_tick, start_tick, finish_deadline,
		current_winner, current_finish_times.duplicate(), current_progress.duplicate(),
		[current_checkpoints[0].duplicate(), current_checkpoints[1].duplicate()], score.duplicate(),
		best_times.duplicate(), round_results.duplicate(true), final_winner]

static func valid(value: Variant) -> bool:
	if not value is Array or value.size() != 24:
		return false
	if not NetPacket.integer(value[0], 1, 2147483647) or not NetPacket.integer(value[1], 1, 2147483647) \
		or not NetPacket.integer(value[2], 1, 10) or not NetPacket.integer(value[3], 1, 10) \
		or int(value[2]) > int(value[3]) or not value[4] is String or value[4].length() > 64 \
		or not NetPacket.integer(value[5], 1, 65535) or not NetPacket.hex(value[6], 64) \
		or not value[7] is String or value[7].length() > 192 \
		or not NetPacket.integer(value[8], 0, Phase.ENDED):
		return false
	for pair_index: int in [9, 11]:
		if not value[pair_index] is Array or value[pair_index].size() != 2 \
			or not value[pair_index][0] is bool or not value[pair_index][1] is bool:
			return false
	for pair_index: int in [10, 12]:
		if not _integer_pair(value[pair_index], -1, 2147483647): return false
	for field: int in [13, 14, 15]:
		if not NetPacket.integer(value[field], -1, 2147483647): return false
	if not NetPacket.integer(value[16], 0, 2) or not _integer_pair(value[17], -1, 2147483647) \
		or not _integer_pair(value[18], 0, 128) or not _checkpoint_pair(value[19]) \
		or not _integer_pair(value[20], 0, 10) or not _integer_pair(value[21], -1, 2147483647) \
		or not value[22] is Array or value[22].size() > 10 \
		or not NetPacket.integer(value[23], -1, 2):
		return false
	for result: Variant in value[22]:
		if not valid_result(result): return false
	return true

static func valid_result(value: Variant) -> bool:
	return value is Array and value.size() == 11 \
		and NetPacket.integer(value[0], 1, 10) and NetPacket.integer(value[1], 1, 2147483647) \
		and value[2] is String and value[2].length() <= 192 \
		and _integer_pair(value[3], 1, 2) and int(value[3][0]) == 1 and int(value[3][1]) == 2 \
		and NetPacket.integer(value[4], 1, 2) and _integer_pair(value[5], -1, 2147483647) \
		and _integer_pair(value[6], FinishStatus.FINISHED, FinishStatus.DNF) \
		and _integer_pair(value[7], 0, 128) and _checkpoint_pair(value[8]) \
		and NetPacket.integer(value[9], -1, 2147483647) \
		and NetPacket.integer(value[10], 0, ResultReason.GUEST_DISCONNECT_TIMEOUT)

static func _integer_pair(value: Variant, minimum: int, maximum: int) -> bool:
	return value is Array and value.size() == 2 and NetPacket.integer(value[0], minimum, maximum) \
		and NetPacket.integer(value[1], minimum, maximum)

static func _checkpoint_pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2:
		return false
	for list: Variant in value:
		if not list is Array or list.size() > 128:
			return false
		var seen: Array = []
		for index: Variant in list:
			if not NetPacket.integer(index, 0, 127) or index in seen: return false
			seen.append(index)
	return true

func apply(value: Array) -> void:
	series_generation = int(value[0]); round_generation = int(value[1])
	round_index = int(value[2]); rounds_total = int(value[3]); map_id = value[4]
	map_version = int(value[5]); map_checksum = value[6]; settings_identity = value[7]
	phase = int(value[8]) as Phase
	loaded.assign(value[9]); loaded_revisions.assign(value[10])
	ready.assign(value[11]); ready_revisions.assign(value[12])
	hint_end_tick = int(value[13]); start_tick = int(value[14]); finish_deadline = int(value[15])
	current_winner = int(value[16]); current_finish_times.assign(value[17])
	current_progress.assign(value[18]); current_checkpoints = value[19].duplicate(true)
	score.assign(value[20]); best_times.assign(value[21]); round_results = value[22].duplicate(true)
	final_winner = int(value[23]); _round_recorded = not round_results.is_empty() \
		and int(round_results.back()[0]) == round_index
