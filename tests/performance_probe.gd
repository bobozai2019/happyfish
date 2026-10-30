extends SceneTree

const OUTPUT_PATH := "res://task/happy_fish_modes/验收/performance_probe.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var scene := (load("res://scenes/game/main.tscn") as PackedScene).instantiate()
	root.add_child(scene)
	for frame in range(30):
		await process_frame
	var director := scene.get_node("World/SpawnDirector") as SpawnDirector
	while director.get_ordinary_count() < SpawnDirector.MAX_ORDINARY_FISH:
		director.spawn_ordinary_fish()

	Input.action_press(&"p1_fire")
	Input.action_press(&"p2_fire")
	var samples: Array[float] = []
	var window_start := Time.get_ticks_usec()
	var frames_in_window := 0
	var started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - started < 10000:
		await process_frame
		frames_in_window += 1
		var now := Time.get_ticks_usec()
		var elapsed := (now - window_start) / 1000000.0
		if elapsed >= 1.0:
			samples.append(frames_in_window / elapsed)
			frames_in_window = 0
			window_start = now
	Input.action_release(&"p1_fire")
	Input.action_release(&"p2_fire")

	var total := 0.0
	var minimum := 999.0
	var sustained_low := false
	var low_run := 0
	for fps in samples:
		total += fps
		minimum = minf(minimum, fps)
		if fps < 55.0:
			low_run += 1
			sustained_low = sustained_low or low_run >= 3
		else:
			low_run = 0
	var average := total / maxf(samples.size(), 1)
	var result := {
		"duration_seconds": (Time.get_ticks_msec() - started) / 1000.0,
		"ordinary_fish": director.get_ordinary_count(),
		"one_second_fps_samples": samples,
		"average_fps": average,
		"minimum_one_second_fps": minimum,
		"sustained_below_55": sustained_low,
		"pass": average >= 55.0 and not sustained_low,
	}
	var file := FileAccess.open(OUTPUT_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("PERFORMANCE: %s" % JSON.stringify(result))
	for player in scene.find_children("*", "AudioStreamPlayer", true, false):
		(player as AudioStreamPlayer).stop()
	scene.queue_free()
	await process_frame
	quit(0 if result.pass else 1)
