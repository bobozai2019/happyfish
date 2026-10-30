extends RefCounted


static func run(tree: SceneTree) -> PackedStringArray:
	var errors := PackedStringArray()
	await _test_single_mouse(tree, errors)
	await _test_single_keyboard(tree, errors)
	await _test_dual_mouse_isolation(tree, errors)
	return errors


static func _test_single_mouse(tree: SceneTree, errors: PackedStringArray) -> void:
	var config := GameSessionConfig.new()
	var battle := await _spawn_battle(tree, config)
	var router := battle.get_node("InputRouter") as PlayerInputRouter
	var cannon := battle.get_node("World/Cannons/P1Cannon") as CannonController
	var session := battle.get_node("Session") as SessionState
	var shots := [0]
	cannon.shot_fired.connect(func(_player_id: int, _level: int, _cost: int) -> void: shots[0] += 1)

	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(960, 180)
	router._unhandled_input(motion)
	if cannon.rotation <= -PI * 0.5 or cannon.rotation > CannonController.MAX_AIM_ANGLE:
		errors.append("单人鼠标移动必须瞄准右上方且不越过角度上限")
	motion.position = Vector2(100, 710)
	router._unhandled_input(motion)
	if not is_equal_approx(cannon.rotation, CannonController.MIN_AIM_ANGLE):
		errors.append("鼠标位于炮台左下方时必须限制为 -170°")

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(900, 240)
	press.pressed = true
	# `_input` 只负责全局释放；GUI 消费的按下事件不得开炮。
	router._input(press)
	if shots[0] != 0:
		errors.append("GUI 消费的鼠标按下不得通过全局输入误开炮")
	router._unhandled_input(press)
	if shots[0] != 1:
		errors.append("战斗区左键按下必须立即发射一发")
	for frame in range(35):
		await tree.physics_frame
	if shots[0] < 2:
		errors.append("单人鼠标长按必须按冷却连续发射")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	router._input(release)
	var released_count: int = shots[0]
	for frame in range(25):
		await tree.physics_frame
	if shots[0] != released_count:
		errors.append("左键释放后必须立即停止后续连发")

	router._unhandled_input(press)
	session.transition_to(SessionState.State.PAUSED)
	session.transition_to(SessionState.State.RUNNING)
	var pause_count: int = shots[0]
	for frame in range(20):
		await tree.physics_frame
	if shots[0] != pause_count:
		errors.append("暂停必须清除鼠标 held 状态")
	router._unhandled_input(press)
	if not router.set_single_control(GameSessionConfig.SinglePlayerControl.KEYBOARD) or cannon._fire_held:
		errors.append("切换单人操作方式必须清除 held 状态")
	router.set_single_control(GameSessionConfig.SinglePlayerControl.MOUSE)
	router._unhandled_input(press)
	router._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if cannon._fire_held:
		errors.append("窗口失焦必须清除 held 状态")

	_resolve_projectiles(battle)
	battle.queue_free()
	await tree.process_frame


static func _test_single_keyboard(tree: SceneTree, errors: PackedStringArray) -> void:
	var config := GameSessionConfig.new()
	config.single_player_control = GameSessionConfig.SinglePlayerControl.KEYBOARD
	var battle := await _spawn_battle(tree, config)
	var cannon := battle.get_node("World/Cannons/P1Cannon") as CannonController
	var before_rotation := cannon.rotation
	var shots := [0]
	cannon.shot_fired.connect(func(_player_id: int, _level: int, _cost: int) -> void: shots[0] += 1)
	Input.action_press(&"p1_aim_left")
	Input.action_press(&"p1_level_up")
	Input.action_press(&"p1_fire")
	for frame in range(3):
		await tree.physics_frame
	Input.action_release(&"p1_aim_left")
	Input.action_release(&"p1_level_up")
	Input.action_release(&"p1_fire")
	if cannon.rotation >= before_rotation or cannon.player_state.current_cannon_level != 1 or shots[0] != 1:
		errors.append("单人键盘必须复用 P1 A/W/Space 瞄准、换挡和开火")
	_resolve_projectiles(battle)
	battle.queue_free()
	await tree.process_frame


static func _test_dual_mouse_isolation(tree: SceneTree, errors: PackedStringArray) -> void:
	var config := GameSessionConfig.new()
	config.game_mode = GameSessionConfig.GameMode.LOCAL_COOP
	var battle := await _spawn_battle(tree, config)
	var router := battle.get_node("InputRouter") as PlayerInputRouter
	var p1 := battle.get_node("World/Cannons/P1Cannon") as CannonController
	var p2 := battle.get_node("World/Cannons/P2Cannon") as CannonController
	var p1_rotation := p1.rotation
	var p2_rotation := p2.rotation
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1000, 100)
	router._unhandled_input(motion)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = motion.position
	router._unhandled_input(press)
	await tree.physics_frame
	if not is_equal_approx(p1.rotation, p1_rotation) or not is_equal_approx(p2.rotation, p2_rotation):
		errors.append("双人模式鼠标不得控制任一炮台")
	if battle.get_node("World/Projectiles").get_child_count() != 0:
		errors.append("双人模式鼠标点击不得开炮")
	battle.queue_free()
	await tree.process_frame


static func _spawn_battle(tree: SceneTree, config: GameSessionConfig) -> Node:
	var battle := (load("res://scenes/game/main.tscn") as PackedScene).instantiate()
	var session := battle.get_node("Session") as SessionState
	if not session.configure(config):
		battle.free()
		return null
	tree.root.add_child(battle)
	await tree.process_frame
	return battle


static func _resolve_projectiles(battle: Node) -> void:
	for projectile in battle.get_node("World/Projectiles").get_children():
		(projectile as Projectile).resolve_once(false)
