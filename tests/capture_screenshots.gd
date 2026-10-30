extends SceneTree

const OUTPUT_DIRECTORY := "res://task/happy_fish_modes/验收/screenshots"


func _initialize() -> void:
	_capture_sequence.call_deferred()


func _capture_sequence() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIRECTORY))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	var flow := (load("res://scenes/main.tscn") as PackedScene).instantiate() as GameFlowController
	root.add_child(flow)
	await _wait_frames(8)
	_save_viewport("mode_select_1280x720.png")

	DisplayServer.window_set_size(Vector2i(1920, 1080))
	await _wait_frames(10)
	_save_viewport("mode_select_1920x1080.png")
	DisplayServer.window_set_size(Vector2i(1280, 720))
	await _wait_frames(8)

	var single_mouse := GameSessionConfig.new()
	flow.start_game(single_mouse)
	await _wait_frames(8)
	_place_showcase_fish(flow.current_game)
	await _wait_frames(5)
	_save_viewport("single_mouse_1280x720.png")

	flow.update_single_control(GameSessionConfig.SinglePlayerControl.KEYBOARD)
	await _wait_frames(4)
	_save_viewport("single_keyboard_1280x720.png")
	var single_ui := flow.current_game.get_node("UI") as UIController
	(single_ui.get_node("HUDRoot/PauseButton") as Button).pressed.emit()
	await _wait_frames(3)
	_save_viewport("single_pause_keyboard_1280x720.png")
	(single_ui.get_node("PauseLayer/CenterPanel/Layout/ReturnSelectButton") as Button).pressed.emit()
	await _wait_frames(2)
	_save_viewport("return_select_confirm_1280x720.png")

	flow.return_to_mode_select()
	await _wait_frames(3)
	var coop := GameSessionConfig.new()
	coop.game_mode = GameSessionConfig.GameMode.LOCAL_COOP
	flow.start_game(coop)
	await _wait_frames(8)
	_place_showcase_fish(flow.current_game)
	await _wait_frames(5)
	_save_viewport("dual_keyboard_1280x720.png")

	flow.return_to_mode_select()
	await _wait_frames(3)
	flow.start_game(single_mouse)
	await _wait_frames(5)
	var session := flow.current_game.get_node("Session") as SessionState
	var p1 := session.get_player(1)
	p1.capture_count = 9
	p1.capture_value = 133
	p1.largest_capture_id = &"golden_arowana"
	p1.largest_capture_value = 60
	p1.rescue_used = true
	p1.coins = 0
	session.evaluate_player_exhaustion(1)
	await _wait_frames(5)
	_save_viewport("single_result_1280x720.png")

	for audio_player in flow.find_children("*", "AudioStreamPlayer", true, false):
		(audio_player as AudioStreamPlayer).stop()
	flow.queue_free()
	await process_frame
	quit(0)


func _wait_frames(count: int) -> void:
	for frame in range(count):
		await process_frame


func _save_viewport(file_name: String) -> void:
	var image := root.get_texture().get_image()
	var path := "%s/%s" % [OUTPUT_DIRECTORY, file_name]
	var error := image.save_png(path)
	if error != OK:
		push_error("截图保存失败：%s (%s)" % [path, error])
	else:
		print("SAVED: %s (%dx%d)" % [path, image.get_width(), image.get_height()])


func _place_showcase_fish(scene: Node) -> void:
	var fish_parent := scene.get_node("World/Fish")
	var ids := ["clownfish", "blue_tang", "pufferfish", "seahorse", "sea_turtle", "manta_ray", "shark", "golden_arowana"]
	var positions := [Vector2(210, 290), Vector2(430, 350), Vector2(650, 270), Vector2(860, 360), Vector2(1080, 285), Vector2(320, 500), Vector2(650, 510), Vector2(990, 500)]
	for index in range(ids.size()):
		var definition := load("res://resources/data/fish/%s.tres" % ids[index]) as FishDefinition
		var actor := (load("res://scenes/game/fish_actor.tscn") as PackedScene).instantiate() as FishActor
		var curve := Curve2D.new()
		curve.add_point(positions[index])
		curve.add_point(positions[index] + Vector2(1000, 0))
		fish_parent.add_child(actor)
		actor.configure(definition, curve, false, 1000 + index, definition.speed_min)
		actor.set_physics_process(false)
		actor.position = positions[index]
