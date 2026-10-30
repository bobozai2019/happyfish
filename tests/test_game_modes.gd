extends RefCounted


static func run(tree: SceneTree) -> PackedStringArray:
	var errors := PackedStringArray()
	_test_config(errors)
	await _test_mode_select(tree, errors)
	await _test_game_flow(tree, errors)
	return errors


static func _test_config(errors: PackedStringArray) -> void:
	var config := GameSessionConfig.new()
	if config.game_mode != GameSessionConfig.GameMode.SINGLE_PLAYER or config.single_player_control != GameSessionConfig.SinglePlayerControl.MOUSE:
		errors.append("GameSessionConfig 默认值必须为单人鼠标")
	if config.get_active_player_ids() != [1] or not config.uses_mouse(1) or config.uses_mouse(2):
		errors.append("单人配置必须只激活 P1 且仅 P1 使用鼠标")
	config.game_mode = GameSessionConfig.GameMode.LOCAL_COOP
	if config.get_active_player_ids() != [1, 2] or config.uses_mouse(1):
		errors.append("双人配置必须激活 P1/P2 并忽略鼠标偏好")
	var copied := config.duplicate_config()
	config.game_mode = GameSessionConfig.GameMode.SINGLE_PLAYER
	if copied == config or copied.game_mode != GameSessionConfig.GameMode.LOCAL_COOP:
		errors.append("duplicate_config 必须返回无共享引用的字段副本")
	if not config.validate().is_empty() or not copied.validate().is_empty():
		errors.append("合法配置不应产生校验错误")


static func _test_mode_select(tree: SceneTree, errors: PackedStringArray) -> void:
	var packed := load("res://scenes/ui/mode_select.tscn") as PackedScene
	var select := packed.instantiate() as ModeSelectController
	tree.root.add_child(select)
	await tree.process_frame
	var selection := select.get_selection()
	if not selection.is_single_player() or selection.single_player_control != GameSessionConfig.SinglePlayerControl.MOUSE:
		errors.append("模式选择页初始必须选中单人鼠标")
	if not select.get_node("Center/Panel/Margin/Layout/ControlSection").visible:
		errors.append("单人模式必须显示操作方式选择")
	(select.get_node("Center/Panel/Margin/Layout/ModeButtons/CoopModeButton") as Button).pressed.emit()
	if select.get_node("Center/Panel/Margin/Layout/ControlSection").visible:
		errors.append("双人模式必须隐藏单人操作方式选择")
	if select.get_selection().game_mode != GameSessionConfig.GameMode.LOCAL_COOP:
		errors.append("双人按钮必须更新 typed config")
	select.queue_free()
	await tree.process_frame


static func _test_game_flow(tree: SceneTree, errors: PackedStringArray) -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var flow := packed.instantiate() as GameFlowController
	tree.root.add_child(flow)
	await tree.process_frame
	if flow.app_state != GameFlowController.AppState.MODE_SELECT or not flow.mode_select.visible:
		errors.append("应用启动必须只显示模式选择")
	if flow.current_game != null or flow.game_container.get_child_count() != 0:
		errors.append("确认模式前不得实例化战斗")

	for cycle in range(3):
		var config := GameSessionConfig.new()
		config.game_mode = GameSessionConfig.GameMode.LOCAL_COOP if cycle == 1 else GameSessionConfig.GameMode.SINGLE_PLAYER
		config.single_player_control = GameSessionConfig.SinglePlayerControl.KEYBOARD if cycle == 2 else GameSessionConfig.SinglePlayerControl.MOUSE
		if not flow.start_game(config):
			errors.append("第 %d 次生命周期开始失败" % (cycle + 1))
			continue
		await tree.process_frame
		if flow.app_state != GameFlowController.AppState.PLAYING or flow.current_game == null or flow.game_container.get_child_count() != 1:
			errors.append("PLAYING 必须且只能有一个战斗实例")
			break
		var session := flow.current_game.get_node("Session") as SessionState
		var expected_mode := config.game_mode
		var p1_cannon := flow.current_game.get_node("World/Cannons/P1Cannon") as CannonController
		var p2_cannon := flow.current_game.get_node("World/Cannons/P2Cannon") as CannonController
		var director := flow.current_game.get_node("World/SpawnDirector") as SpawnDirector
		if expected_mode == GameSessionConfig.GameMode.SINGLE_PLAYER:
			if session.get_active_player_ids() != [1] or session.get_player(2) != null:
				errors.append("单人模式必须只创建 P1 PlayerState")
			if not p1_cannon.position.is_equal_approx(Vector2(640, 670)) or p2_cannon.visible or p2_cannon.process_mode != Node.PROCESS_MODE_DISABLED:
				errors.append("单人模式必须使用中央 P1 炮台并禁用 P2")
			if director.first_boss_captures != 10:
				errors.append("单人 Boss 首次捕获阈值必须为 10")
			director.set_total_captures(9)
			director.advance_schedule(0.0)
			if director.boss_state != SpawnDirector.BossState.READY:
				errors.append("单人第 9 次捕获不得触发 Boss")
			director.set_total_captures(10)
			director.advance_schedule(0.0)
			if director.boss_state != SpawnDirector.BossState.WARNING:
				errors.append("单人第 10 次捕获必须触发 Boss 预告")
			var p1 := session.get_player(1)
			p1.coins = 0
			session.evaluate_player_exhaustion(1)
			if p1.coins != 30 or not p1.rescue_used or p1.is_exhausted:
				errors.append("单人第一次真正耗尽必须获得一次 30 金币救援")
			p1.coins = 0
			session.evaluate_player_exhaustion(1)
			if not p1.is_exhausted or session.state != SessionState.State.RESULTS:
				errors.append("单人第二次耗尽且 pending 为 0 必须直接结算")
		else:
			if session.get_active_player_ids() != [1, 2] or session.get_player(2) == null or not p2_cannon.visible:
				errors.append("双人模式必须保持两名玩家和两座炮台")
			if director.first_boss_captures != 18:
				errors.append("双人 Boss 首次捕获阈值必须保持 18")
		config.game_mode = GameSessionConfig.GameMode.LOCAL_COOP if expected_mode == GameSessionConfig.GameMode.SINGLE_PLAYER else GameSessionConfig.GameMode.SINGLE_PLAYER
		if session.config == config or session.config.game_mode != expected_mode:
			errors.append("GameFlow 必须在跨层传递时复制配置")
		if not flow.restart_current_game() or session.get_player(1).coins != 120:
			errors.append("重开必须复用配置并重建玩家状态")
		flow.return_to_mode_select()
		await tree.process_frame
		await tree.process_frame
		if flow.app_state != GameFlowController.AppState.MODE_SELECT or flow.current_game != null or flow.game_container.get_child_count() != 0:
			errors.append("返回选择必须销毁战斗且无残留实例")
			break

	flow.queue_free()
	await tree.process_frame
