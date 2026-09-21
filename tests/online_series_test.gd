extends SceneTree
## M21 transport-independent authority, generation, result and presentation regression suite.

var failures: int = 0

func _initialize() -> void:
	run.call_deferred()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("M21: " + message)

func loaded(series: OnlineSeries, player: int, revision: int = 1) -> bool:
	return series.confirm_loaded(player, series.series_generation, series.round_generation,
		series.map_id, series.map_version, series.map_checksum, revision)

func run() -> void:
	var definition: MapDefinition = MapCatalog.training()
	var series := OnlineSeries.new()
	check(series.configure(definition, 2), "valid immutable settings")
	check(series.phase == OnlineSeries.Phase.SYNCHRONIZED_LOADING and series.loaded == [false, false],
		"series starts in synchronized loading")
	check(not series.confirm_loaded(1, 0, 1, definition.map_id, definition.map_version,
		definition.declared_checksum, 1), "stale series load rejected")
	check(not series.confirm_loaded(1, 1, 2, definition.map_id, definition.map_version,
		definition.declared_checksum, 1), "future round load rejected")
	check(not series.confirm_loaded(1, 1, 1, definition.map_id, definition.map_version,
		"f".repeat(64), 1), "wrong checksum load rejected")
	check(loaded(series, 1) and not series.begin_hint(10, 180), "host waits for both actual loads")
	check(loaded(series, 2) and series.begin_hint(10, 180), "both loads begin controls hint")
	check(series.hint_end_tick == 190 and not series.begin_countdown(370, 189),
		"hint cannot end early")
	check(series.begin_countdown(370, 190) and not series.begin_race(369)
		and series.begin_race(370), "one authoritative countdown/start tick")
	check(series.record_finish(2, 600, 7, [0, 1, 2, 3, 4, 5, 6], 700),
		"first valid finisher accepted")
	check(series.current_winner == 2 and series.finish_deadline == 2500
		and series.phase == OnlineSeries.Phase.FINISH_WINDOW, "exact 30-second remaining window")
	check(not series.record_finish(2, 601, 7, [0, 1, 2, 3, 4, 5, 6], 701),
		"duplicate Finish immutable")
	check(not series.expire_finish_window(2499, [7, 6], [[0], [0]]), "timeout boundary not early")
	check(series.record_finish(1, 2400, 7, [0, 1, 2, 3, 4, 5, 6], 2500),
		"second Finish accepted exactly at deadline")
	check(series.phase == OnlineSeries.Phase.ROUND_RESULTS and series.score == [0, 1]
		and series.round_results.size() == 1, "round result and one win recorded once")
	var first_result: String = JSON.stringify(series.round_results[0])
	check(not series.record_finish(1, 1, 7, [], 2500)
		and JSON.stringify(series.round_results[0]) == first_result, "late Finish cannot rewrite result")
	check(series.enter_between_round() and series.phase == OnlineSeries.Phase.BETWEEN_ROUND_READY,
		"results advance to explicit between-round readiness")
	check(not series.set_ready(1, true, 0, 1, 1), "stale series Ready rejected")
	check(series.set_ready(1, true, 1, 1, 1) and not series.begin_next_round(),
		"one player cannot start next round")
	check(series.set_ready(2, true, 1, 1, 1) and series.begin_next_round(),
		"both Ready atomically start next load")
	check(series.round_index == 2 and series.round_generation == 2 and series.loaded == [false, false]
		and series.ready == [false, false] and series.current_finish_times == [-1, -1],
		"readiness and complete round state reset")
	check(not series.confirm_loaded(2, 1, 1, definition.map_id, definition.map_version,
		definition.declared_checksum, 99), "late prior-round load rejected")
	loaded(series, 1); loaded(series, 2); series.begin_hint(3000, 0)
	series.begin_countdown(3001, 3000); series.begin_race(3001)
	check(series.record_finish(1, 500, 7, [0, 1, 2, 3, 4, 5, 6], 4000),
		"round two winner accepted")
	check(not series.expire_finish_window(5799, [7, 6], [[0, 1, 2, 3, 4, 5, 6], [0, 1, 2, 3, 4, 5]]),
		"DNF deadline remains exact")
	check(series.expire_finish_window(5800, [7, 6], [[0, 1, 2, 3, 4, 5, 6], [0, 1, 2, 3, 4, 5]]),
		"unfinished second player receives timeout DNF")
	check(series.round_results[1][6][1] == OnlineSeries.FinishStatus.DNF
		and series.score == [1, 1], "DNF evidence and score")
	check(series.enter_between_round() and series.phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS
		and series.final_winner == 0, "even score is Draw without tiebreaker")
	check(series.best_times == [500, 600] and OnlineSeries.valid(series.capture()),
		"best valid times and complete wire state")
	var prior_generation: int = series.series_generation
	check(series.play_again() and series.series_generation == prior_generation + 1
		and series.round_results.is_empty() and series.score == [0, 0] and series.ready == [false, false],
		"Play Again creates clean series generation")
	series.phase = OnlineSeries.Phase.FINAL_SERIES_RESULTS
	check(series.return_to_lobby() and series.phase == OnlineSeries.Phase.LOBBY,
		"Return to Lobby keeps immutable membership/settings object")
	series.end()
	check(series.phase == OnlineSeries.Phase.ENDED, "Main Menu/host loss terminal cleanup state")

	var single := OnlineSeries.new()
	single.configure(definition, 1); loaded(single, 1); loaded(single, 2)
	single.begin_hint(0, 0); single.begin_countdown(1, 0); single.begin_race(1)
	single.record_finish(1, 60, 7, [0, 1, 2, 3, 4, 5, 6], 60)
	single.expire_finish_window(1860, [7, 0], [[0, 1, 2, 3, 4, 5, 6], []])
	single.enter_between_round()
	check(single.phase == OnlineSeries.Phase.FINAL_SERIES_RESULTS and single.final_winner == 1,
		"one-round series final winner")
	var disconnect := OnlineSeries.new()
	disconnect.configure(definition, 1); loaded(disconnect, 1); loaded(disconnect, 2)
	disconnect.begin_hint(0, 0); disconnect.begin_countdown(1, 0); disconnect.begin_race(1)
	check(disconnect.enter_reconnect() and disconnect.award_guest_disconnect([4, 3],
		[[0, 1, 2, 3], [0, 1, 2]]), "guest timeout awards current round to host")
	check(not disconnect.award_guest_disconnect([4, 3], [[], []]) and disconnect.score == [1, 0]
		and disconnect.round_results.size() == 1 \
		and disconnect.round_results[0][10] == OnlineSeries.ResultReason.GUEST_DISCONNECT_TIMEOUT,
		"disconnect award is exactly once with progress evidence")
	check(not OnlineSeries.new().configure(definition, 0) and not OnlineSeries.new().configure(definition, 11),
		"round setting remains bounded 1..10")

	for repetition: int in 50:
		var repeat := OnlineSeries.new()
		repeat.configure(definition, 1, repetition + 1)
		loaded(repeat, 1); loaded(repeat, 2); repeat.begin_hint(0, 0)
		repeat.begin_countdown(1, 0); repeat.begin_race(1)
		repeat.record_finish(1, 10, 7, [0, 1, 2, 3, 4, 5, 6], 10)
		repeat.expire_finish_window(1810, [7, 0], [[0, 1, 2, 3, 4, 5, 6], []])
		repeat.enter_between_round(); repeat.play_again()
		check(repeat.round_results.is_empty() and repeat.ready == [false, false],
			"repeated lifecycle cleanup %d" % repetition)

	if failures == 0:
		print("PROJECTVELOCITY_M21_SERIES_OK")
	quit(0 if failures == 0 else 1)
