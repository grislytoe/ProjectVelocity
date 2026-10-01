extends SceneTree
## Renderer sanity only; this is not the dedicated M24 benchmark.


func _initialize() -> void:
	run.call_deferred()


func percentile(values: Array[float], ratio: float) -> float:
	values.sort()
	return values[clampi(ceili((values.size() - 1) * ratio), 0, values.size() - 1)]


func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/validation/m23")
	var layer := InputLayer.new()
	root.add_child(layer)
	var start_usec: int = Time.get_ticks_usec()
	var course := SoloCourse.new()
	course.definition = MapCatalog.industrial()
	course.input_layer = layer
	root.add_child(course)
	var construct_ms: float = (Time.get_ticks_usec() - start_usec) / 1000.0
	for frame: int in 30:
		await process_frame
	var frame_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var primitives: Array[float] = []
	for frame: int in 180:
		var before: int = Time.get_ticks_usec()
		await process_frame
		frame_ms.append((Time.get_ticks_usec() - before) / 1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var report := {
		"renderer": RenderingServer.get_video_adapter_name(),
		"display_server": DisplayServer.get_name(),
		"samples": frame_ms.size(),
		"frame_ms_p50": percentile(frame_ms.duplicate(), 0.50),
		"frame_ms_p95": percentile(frame_ms.duplicate(), 0.95),
		"frame_ms_max": frame_ms.max(),
		"draw_calls_p95": percentile(draw_calls.duplicate(), 0.95),
		"draw_calls_max": draw_calls.max(),
		"primitives_p95": percentile(primitives.duplicate(), 0.95),
		"course_construct_ms": construct_ms,
		"committed_raster_rgba_bytes": 2097152,
		"texture_preloaded": IndustrialFoundryBackground.PLATE != null,
		"physics_hz": Engine.physics_ticks_per_second,
	}
	var file := FileAccess.open("res://builds/validation/m23/performance.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	file.close()
	print("PROJECTVELOCITY_M23_PERF_SANITY ", JSON.stringify(report))
	course.free()
	layer.free()
	quit()
