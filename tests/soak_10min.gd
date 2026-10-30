extends SceneTree

const TARGET_PHYSICS_FRAMES := 36000

var mode_name := "dual"
var output_path := "res://task/happy_fish_modes/验收/soak_dual_10min.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument == "--mode=single":
			mode_name = "single"
			output_path = "res://task/happy_fish_modes/验收/soak_single_10min.json"
	var scene := (load("res://scenes/game/main.tscn") as PackedScene).instantiate()
	var requested_config := GameSessionConfig.new()
	requested_config.game_mode = GameSessionConfig.GameMode.SINGLE_PLAYER if mode_name == "single" else GameSessionConfig.GameMode.LOCAL_COOP
	requested_config.single_player_control = GameSessionConfig.SinglePlayerControl.KEYBOARD
	if not (scene.get_node("Session") as SessionState).configure(requested_config):
		push_error("SOAK 无法注入 %s 配置" % mode_name)
		quit(1)
		return
	root.add_child(scene)
	await process_frame
	var session := scene.get_node("Session") as SessionState
	var director := scene.get_node("World/SpawnDirector") as SpawnDirector
	var errors := PackedStringArray()
	var restarts := 0
	var max_ordinary := 0
	var started := Time.get_ticks_msec()
	_write_progress({"status": "running", "mode": mode_name, "started_ticks_msec": started, "target_frames": TARGET_PHYSICS_FRAMES})

	for frame in range(TARGET_PHYSICS_FRAMES):
		_drive_inputs(frame, mode_name == "dual")
		await physics_frame
		max_ordinary = maxi(max_ordinary, director.get_ordinary_count())
		for player_id in session.get_active_player_ids():
			var player := session.get_player(player_id)
			if player.coins < 0:
				errors.append("P%d coins negative at frame %d" % [player_id, frame])
			if player.pending_resolution_count < 0:
				errors.append("P%d pending negative at frame %d" % [player_id, frame])
		if director.get_ordinary_count() > SpawnDirector.MAX_ORDINARY_FISH:
			errors.append("ordinary fish exceeded cap at frame %d" % frame)
		if session.state == SessionState.State.RESULTS:
			session.start_new_session()
			restarts += 1
		if frame > 0 and frame % 3600 == 0:
			_write_progress({"status": "running", "mode": mode_name, "frame": frame, "elapsed_seconds": (Time.get_ticks_msec() - started) / 1000.0, "restarts": restarts, "errors": errors.size()})

	_release_all_inputs()
	for projectile in scene.get_node("World/Projectiles").get_children():
		(projectile as Projectile).resolve_once(false)
	for frame in range(5):
		await physics_frame
	for player in session.get_active_players():
		if player.pending_resolution_count != 0:
			errors.append("P%d pending leaked after final release: %d" % [player.player_id, player.pending_resolution_count])
	var elapsed_seconds := (Time.get_ticks_msec() - started) / 1000.0
	var result := {
		"status": "complete",
		"mode": mode_name,
		"physics_frames": TARGET_PHYSICS_FRAMES,
		"elapsed_seconds": elapsed_seconds,
		"restarts": restarts,
		"max_ordinary_fish": max_ordinary,
		"errors": Array(errors),
		"pass": errors.is_empty() and elapsed_seconds >= 590.0,
	}
	_write_progress(result)
	print("SOAK: %s" % JSON.stringify(result))
	scene.queue_free()
	await process_frame
	quit(0 if result.pass else 1)


func _drive_inputs(frame: int, dual: bool) -> void:
	if frame % 180 == 0:
		Input.action_press(&"p1_level_up")
		if dual:
			Input.action_press(&"p2_level_down")
	elif frame % 180 == 2:
		Input.action_release(&"p1_level_up")
		Input.action_release(&"p2_level_down")
	if frame % 240 < 120:
		Input.action_press(&"p1_fire")
		if dual:
			Input.action_press(&"p2_fire")
	else:
		Input.action_release(&"p1_fire")
		Input.action_release(&"p2_fire")
	var aim_phase := frame % 360
	_set_action(&"p1_aim_left", aim_phase < 90)
	_set_action(&"p1_aim_right", aim_phase >= 180 and aim_phase < 270)
	_set_action(&"p2_aim_right", dual and aim_phase < 90)
	_set_action(&"p2_aim_left", dual and aim_phase >= 180 and aim_phase < 270)


func _set_action(action: StringName, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)


func _release_all_inputs() -> void:
	for action in [&"p1_aim_left", &"p1_aim_right", &"p1_level_up", &"p1_level_down", &"p1_fire", &"p2_aim_left", &"p2_aim_right", &"p2_level_up", &"p2_level_down", &"p2_fire"]:
		Input.action_release(action)


func _write_progress(data: Dictionary) -> void:
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
