extends RefCounted

const FISH_DIRECTORY := "res://resources/data/fish"
const CANNON_DIRECTORY := "res://resources/data/cannons"

const EXPECTED_FISH := {
	&"clownfish": [2, 0.35, 24.0, 140.0, 180.0, false],
	&"blue_tang": [4, 0.20, 20.0, 130.0, 165.0, false],
	&"pufferfish": [7, 0.12, 16.0, 90.0, 120.0, false],
	&"seahorse": [10, 0.08, 13.0, 80.0, 105.0, false],
	&"sea_turtle": [15, 0.055, 10.0, 65.0, 90.0, false],
	&"manta_ray": [25, 0.034, 8.0, 85.0, 115.0, false],
	&"shark": [40, 0.022, 6.0, 110.0, 145.0, false],
	&"golden_arowana": [60, 0.015, 3.0, 120.0, 155.0, false],
	&"whale_shark_boss": [200, 0.004, 0.0, 55.0, 75.0, true],
}

const EXPECTED_CANNONS := {
	1: [1, 1.0, 72.0, 0.25, 900.0],
	2: [2, 1.9, 84.0, 0.25, 900.0],
	5: [5, 4.2, 104.0, 0.25, 900.0],
}


static func run() -> PackedStringArray:
	var errors := PackedStringArray()
	_test_fish_resources(errors)
	_test_cannon_resources(errors)
	_test_player_state(errors)
	_test_input_map(errors)
	return errors


static func _test_fish_resources(errors: PackedStringArray) -> void:
	var seen_ids: Dictionary = {}
	var ordinary_count := 0
	var boss_count := 0
	for fish_id: StringName in EXPECTED_FISH:
		var path := "%s/%s.tres" % [FISH_DIRECTORY, fish_id]
		var fish := load(path) as FishDefinition
		if fish == null:
			errors.append("无法加载 FishDefinition：%s" % path)
			continue
		for validation_error in fish.validate():
			errors.append("%s: %s" % [path, validation_error])
		if fish.sprite_frames.get_frame_count(&"swim") < 2:
			errors.append("%s 的 swim 动画至少需要 2 帧" % path)
		else:
			for frame_index in range(fish.sprite_frames.get_frame_count(&"swim")):
				if fish.sprite_frames.get_frame_texture(&"swim", frame_index) == null:
					errors.append("%s 的 swim 第 %d 帧缺少纹理" % [path, frame_index])
		if seen_ids.has(fish.id):
			errors.append("鱼 id 重复：%s" % fish.id)
		seen_ids[fish.id] = true
		if fish.id != fish_id:
			errors.append("%s 的 id 应为 %s，实际为 %s" % [path, fish_id, fish.id])
		var expected: Array = EXPECTED_FISH[fish_id]
		_expect_equal(errors, path, "reward", fish.reward, expected[0])
		_expect_float(errors, path, "base_capture_chance", fish.base_capture_chance, expected[1])
		_expect_float(errors, path, "spawn_weight", fish.spawn_weight, expected[2])
		_expect_float(errors, path, "speed_min", fish.speed_min, expected[3])
		_expect_float(errors, path, "speed_max", fish.speed_max, expected[4])
		_expect_equal(errors, path, "is_boss", fish.is_boss, expected[5])
		if fish.is_boss:
			boss_count += 1
		else:
			ordinary_count += 1
	_expect_equal(errors, FISH_DIRECTORY, "普通鱼数量", ordinary_count, 8)
	_expect_equal(errors, FISH_DIRECTORY, "Boss 数量", boss_count, 1)


static func _test_cannon_resources(errors: PackedStringArray) -> void:
	for multiplier: int in EXPECTED_CANNONS:
		var path := "%s/cannon_%dx.tres" % [CANNON_DIRECTORY, multiplier]
		var cannon := load(path) as CannonDefinition
		if cannon == null:
			errors.append("无法加载 CannonDefinition：%s" % path)
			continue
		for validation_error in cannon.validate():
			errors.append("%s: %s" % [path, validation_error])
		var expected: Array = EXPECTED_CANNONS[multiplier]
		_expect_equal(errors, path, "multiplier", cannon.multiplier, multiplier)
		_expect_equal(errors, path, "shot_cost", cannon.shot_cost, expected[0])
		_expect_float(errors, path, "probability_multiplier", cannon.probability_multiplier, expected[1])
		_expect_float(errors, path, "net_radius_px", cannon.net_radius_px, expected[2])
		_expect_float(errors, path, "fire_interval_sec", cannon.fire_interval_sec, expected[3])
		_expect_float(errors, path, "projectile_speed", cannon.projectile_speed, expected[4])


static func _test_player_state(errors: PackedStringArray) -> void:
	var player := PlayerState.new(2)
	_expect_equal(errors, "PlayerState", "player_id", player.player_id, 2)
	_expect_equal(errors, "PlayerState", "coins", player.coins, 120)
	_expect_equal(errors, "PlayerState", "current_cannon_level", player.current_cannon_level, 0)
	_expect_equal(errors, "PlayerState", "rescue_used", player.rescue_used, false)
	_expect_equal(errors, "PlayerState", "is_exhausted", player.is_exhausted, false)
	_expect_equal(errors, "PlayerState", "pending_resolution_count", player.pending_resolution_count, 0)
	if not player.spend(5) or player.coins != 115:
		errors.append("PlayerState 合法扣费失败")
	if player.spend(999) or player.coins != 115:
		errors.append("PlayerState 不应允许余额不足扣费")
	player.begin_pending_resolution()
	if not player.finish_pending_resolution() or player.finish_pending_resolution():
		errors.append("PlayerState pending 必须成对且不得减为负数")
	player.empty_net_streak = 5
	player.record_capture(&"shark", 40)
	if player.coins != 155 or player.capture_count != 1 or player.capture_value != 40:
		errors.append("PlayerState 捕获统计或金币更新错误")
	if player.empty_net_streak != 0 or player.largest_capture_id != &"shark" or player.largest_capture_value != 40:
		errors.append("PlayerState 捕获后保底或最大鱼更新错误")
	player.coins = -10
	player.pending_resolution_count = -1
	if player.coins != 0 or player.pending_resolution_count != 0:
		errors.append("PlayerState 非负不变量未保持")


static func _test_input_map(errors: PackedStringArray) -> void:
	var expected_actions: Array[StringName] = [
		&"p1_aim_left", &"p1_aim_right", &"p1_level_up", &"p1_level_down", &"p1_fire",
		&"p2_aim_left", &"p2_aim_right", &"p2_level_up", &"p2_level_down", &"p2_fire",
		&"pause_game", &"restart_game",
	]
	for action in expected_actions:
		if not InputMap.has_action(action):
			errors.append("InputMap 缺少动作：%s" % action)
		elif InputMap.action_get_events(action).is_empty():
			errors.append("InputMap 动作没有默认按键：%s" % action)
	_test_art_and_audio_assets(errors)


static func _test_art_and_audio_assets(errors: PackedStringArray) -> void:
	var background := load("res://resources/art/background/ocean_arena.png") as Texture2D
	if background == null or background.get_size() != Vector2(1280, 720):
		errors.append("海底背景必须可加载且为 1280×720")
	var audio_paths := [
		"res://resources/audio/music/happy_reef_loop.wav",
		"res://resources/audio/sfx/shot.wav",
		"res://resources/audio/sfx/net.wav",
		"res://resources/audio/sfx/capture.wav",
		"res://resources/audio/sfx/boss_warning.wav",
		"res://resources/audio/sfx/button.wav",
		"res://resources/audio/sfx/rescue.wav",
	]
	for path in audio_paths:
		var stream := load(path) as AudioStream
		if stream == null or stream.get_length() <= 0.0:
			errors.append("音频资源不可播放：%s" % path)


static func _expect_equal(errors: PackedStringArray, context: String, field: String, actual: Variant, expected: Variant) -> void:
	if actual != expected:
		errors.append("%s 的 %s 应为 %s，实际为 %s" % [context, field, expected, actual])


static func _expect_float(errors: PackedStringArray, context: String, field: String, actual: float, expected: float) -> void:
	if not is_equal_approx(actual, expected):
		errors.append("%s 的 %s 应为 %s，实际为 %s" % [context, field, expected, actual])
