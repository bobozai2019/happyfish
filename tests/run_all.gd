extends SceneTree

const DataResourceTests = preload("res://tests/test_data_resources.gd")
const GameplayObjectTests = preload("res://tests/test_gameplay_objects.gd")
const CaptureSessionTests = preload("res://tests/test_capture_session.gd")
const UIFlowTests = preload("res://tests/test_ui_flow.gd")
const GameModeTests = preload("res://tests/test_game_modes.gd")
const InputRouterTests = preload("res://tests/test_input_router.gd")
const MAIN_SCENE_PATH := "res://scenes/game/main.tscn"
const REQUIRED_NODES: Array[NodePath] = [
	NodePath("World/Background"),
	NodePath("World/Paths"),
	NodePath("World/Fish"),
	NodePath("World/Cannons"),
	NodePath("World/Projectiles"),
	NodePath("World/Effects"),
	NodePath("UI/HUDRoot"),
	NodePath("UI/PauseLayer"),
	NodePath("UI/ResultsLayer"),
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var exit_code := 0
	var packed_scene := load(MAIN_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("无法加载主场景：%s" % MAIN_SCENE_PATH)
		quit(1)
		return

	var scene := packed_scene.instantiate()
	root.add_child(scene)
	await process_frame
	for node_path in REQUIRED_NODES:
		if scene.get_node_or_null(node_path) == null:
			push_error("主场景缺少静态节点：%s" % node_path)
			exit_code = 1

	for test_error in DataResourceTests.run():
		push_error(test_error)
		exit_code = 1
	for test_error in await GameplayObjectTests.run(self, scene):
		push_error(test_error)
		exit_code = 1
	for test_error in await CaptureSessionTests.run(self, scene):
		push_error(test_error)
		exit_code = 1
	for test_error in await UIFlowTests.run(self, scene):
		push_error(test_error)
		exit_code = 1
	for test_error in await GameModeTests.run(self):
		push_error(test_error)
		exit_code = 1
	for test_error in await InputRouterTests.run(self):
		push_error(test_error)
		exit_code = 1
	for audio_player in scene.find_children("*", "AudioStreamPlayer", true, false):
		(audio_player as AudioStreamPlayer).stop()
	scene.queue_free()
	await process_frame
	await process_frame
	if exit_code == 0:
		print("PASS: 旧双人回归与 Gate 3 模式/输入/UI 校验通过")
	quit(exit_code)
