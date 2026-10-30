extends RefCounted


static func run(tree: SceneTree, main_scene: Node) -> PackedStringArray:
	var errors := PackedStringArray()
	var session := main_scene.get_node("Session") as SessionState
	var ui := main_scene.get_node("UI") as UIController
	ui.restart_requested.connect(session.start_new_session)
	session.start_new_session()
	await tree.process_frame

	session.coins_changed.emit(1, 120, 87)
	session.shot_fired.emit(2, 2, 5)
	if (ui.get_node("HUDRoot/P1Panel/Layout/Coins") as Label).text != "金币  87":
		errors.append("P1 HUD 金币必须独立实时更新")
	if (ui.get_node("HUDRoot/P2Panel/Layout/Multiplier") as Label).text != "炮倍  5×":
		errors.append("P2 HUD 炮倍必须独立实时更新")

	session.player_rescued.emit(1, 30)
	var message := ui.get_node("HUDRoot/MessageBanner/Text") as Label
	if not ui.get_node("HUDRoot/MessageBanner").visible or "救援金币 +30" not in message.text:
		errors.append("救援提示必须显示积极中文文案和 +30")
	session.player_exhausted.emit(2)
	if "等待伙伴" not in (ui.get_node("HUDRoot/P2Panel/Layout/Status") as Label).text:
		errors.append("耗尽玩家 HUD 必须显示等待伙伴")

	(ui.get_node("HUDRoot/PauseButton") as Button).pressed.emit()
	if session.state != SessionState.State.PAUSED or not ui.get_node("PauseLayer").visible:
		errors.append("暂停按钮必须进入 PAUSED 并显示暂停层")
	(ui.get_node("PauseLayer/CenterPanel/Layout/ContinueButton") as Button).pressed.emit()
	if session.state != SessionState.State.RUNNING or ui.get_node("PauseLayer").visible:
		errors.append("继续按钮必须恢复 RUNNING 并隐藏暂停层")

	var p1 := session.get_player(1)
	var p2 := session.get_player(2)
	p1.capture_count = 4
	p1.capture_value = 25
	p1.largest_capture_id = &"sea_turtle"
	p1.largest_capture_value = 15
	p2.capture_count = 6
	p2.capture_value = 40
	p2.largest_capture_id = &"shark"
	p2.largest_capture_value = 40
	for player in [p1, p2]:
		player.rescue_used = true
		player.coins = 0
		session.evaluate_player_exhaustion(player.player_id)
	if session.state != SessionState.State.RESULTS or not ui.get_node("ResultsLayer").visible:
		errors.append("双方耗尽后必须显示结果层")
	var result_text := _collect_label_text(ui.get_node("ResultsLayer"))
	if "玩家 1" not in result_text or "玩家 2" not in result_text or "捕获 4 条" not in result_text or "捕获 6 条" not in result_text:
		errors.append("结果层必须并列展示双方捕获统计")
	if "冠军" in result_text or "失败" in result_text or "输家" in result_text:
		errors.append("结果层不得宣布冠军、失败者或输家")

	(ui.get_node("ResultsLayer/CenterPanel/Layout/RestartButton") as Button).pressed.emit()
	await tree.process_frame
	if session.state != SessionState.State.RUNNING or ui.get_node("ResultsLayer").visible:
		errors.append("结果层按钮必须开始全新一局")

	await _test_responsive_hud(tree, errors)
	await _test_mode_specific_ui(tree, errors)
	return errors


static func _test_responsive_hud(tree: SceneTree, errors: PackedStringArray) -> void:
	var fixture := Control.new()
	fixture.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tree.root.add_child(fixture)
	var hud := (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate() as Control
	fixture.add_child(hud)
	for viewport_size in [Vector2(1024, 576), Vector2(1280, 720), Vector2(1920, 1080)]:
		fixture.size = viewport_size
		await tree.process_frame
		var p1_rect := (hud.get_node("P1Panel") as Control).get_rect()
		var p2_rect := (hud.get_node("P2Panel") as Control).get_rect()
		var pause_rect := (hud.get_node("PauseButton") as Control).get_rect()
		if p1_rect.end.x >= pause_rect.position.x or pause_rect.end.x >= p2_rect.position.x:
			errors.append("HUD 在 %dx%d 下发生顶部控件重叠" % [viewport_size.x, viewport_size.y])
		var mouse_controls := hud.get_node("SingleMouseControls") as Control
		mouse_controls.visible = true
		await tree.process_frame
		var controls_rect := mouse_controls.get_rect()
		if controls_rect.position.x < 0.0 or controls_rect.end.x > viewport_size.x or controls_rect.position.y < 0.0 or controls_rect.end.y > viewport_size.y:
			errors.append("单人鼠标操作按钮在 %dx%d 下超出画面" % [viewport_size.x, viewport_size.y])
	fixture.queue_free()
	await tree.process_frame


static func _test_mode_specific_ui(tree: SceneTree, errors: PackedStringArray) -> void:
	var flow := (load("res://scenes/main.tscn") as PackedScene).instantiate() as GameFlowController
	tree.root.add_child(flow)
	await tree.process_frame
	var config := GameSessionConfig.new()
	if not flow.start_game(config):
		errors.append("UI 模式测试无法启动单人鼠标局")
		flow.queue_free()
		return
	await tree.process_frame
	var game := flow.current_game
	var session := game.get_node("Session") as SessionState
	var ui := game.get_node("UI") as UIController
	var router := game.get_node("InputRouter") as PlayerInputRouter
	var cannon := game.get_node("World/Cannons/P1Cannon") as CannonController
	if (ui.get_node("HUDRoot/P2Panel") as Control).visible or not (ui.get_node("HUDRoot/SingleMouseControls") as Control).visible:
		errors.append("单人鼠标 HUD 必须隐藏 P2 并显示操作按钮")
	(ui.get_node("HUDRoot/SingleMouseControls/LevelUpButton") as Button).pressed.emit()
	if cannon.player_state.current_cannon_level != 1:
		errors.append("HUD ＋ 按钮必须通过 InputRouter 切换炮倍")
	if (ui.get_node("HUDRoot/P1Panel/Layout/Multiplier") as Label).text != "炮倍  2×":
		errors.append("HUD ＋ 按钮切换后必须立即刷新倍率文字")
	(ui.get_node("HUDRoot/SingleMouseControls/FireButton") as Button).button_down.emit()
	(ui.get_node("HUDRoot/SingleMouseControls/FireButton") as Button).button_up.emit()
	if game.get_node("World/Projectiles").get_child_count() != 1:
		errors.append("HUD 开炮按钮按下必须立即发射且松开结束 held")
	for projectile in game.get_node("World/Projectiles").get_children():
		(projectile as Projectile).resolve_once(false)
	await tree.physics_frame

	(ui.get_node("HUDRoot/PauseButton") as Button).pressed.emit()
	(ui.get_node("PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/KeyboardControlButton") as Button).pressed.emit()
	if flow.current_config.single_player_control != GameSessionConfig.SinglePlayerControl.KEYBOARD or router.config.single_player_control != GameSessionConfig.SinglePlayerControl.KEYBOARD:
		errors.append("暂停层切换键盘必须同步 GameFlow 与 InputRouter")
	if (ui.get_node("HUDRoot/SingleMouseControls") as Control).visible:
		errors.append("单人键盘模式必须隐藏鼠标操作按钮")
	(ui.get_node("PauseLayer/CenterPanel/Layout/ContinueButton") as Button).pressed.emit()
	var p1 := session.get_player(1)
	p1.rescue_used = true
	p1.coins = 0
	session.evaluate_player_exhaustion(1)
	if session.state != SessionState.State.RESULTS:
		errors.append("单人 UI 夹具未进入结果状态")
	if (ui.get_node("ResultsLayer/CenterPanel/Layout/P2Stats") as Control).visible:
		errors.append("单人结果必须隐藏 P2 统计")
	var result_text := _collect_label_text(ui.get_node("ResultsLayer"))
	if "你的本局收获" not in result_text or "伙伴" in result_text or "玩家 2" in result_text:
		errors.append("单人结果必须是个人统计且不出现 P2/伙伴文案")

	(ui.get_node("ResultsLayer/CenterPanel/Layout/RestartButton") as Button).pressed.emit()
	await tree.process_frame
	if session.state != SessionState.State.RUNNING or flow.current_config.single_player_control != GameSessionConfig.SinglePlayerControl.KEYBOARD:
		errors.append("结果页再来一局必须保留单人键盘配置")
	(ui.get_node("HUDRoot/PauseButton") as Button).pressed.emit()
	(ui.get_node("PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/MouseControlButton") as Button).pressed.emit()
	if not (ui.get_node("HUDRoot/SingleMouseControls") as Control).visible or router.config.single_player_control != GameSessionConfig.SinglePlayerControl.MOUSE:
		errors.append("暂停层切回鼠标必须立即刷新 HUD 与路由")
	(ui.get_node("PauseLayer/CenterPanel/Layout/ReturnSelectButton") as Button).pressed.emit()
	if not (ui.get_node("PauseLayer/ConfirmPanel") as Control).visible:
		errors.append("返回模式选择必须先显示确认层")
	(ui.get_node("PauseLayer/ConfirmPanel/Layout/Buttons/ConfirmButton") as Button).pressed.emit()
	await tree.process_frame
	await tree.process_frame
	if flow.app_state != GameFlowController.AppState.MODE_SELECT or flow.current_game != null or flow.game_container.get_child_count() != 0:
		errors.append("确认返回后必须销毁战斗并恢复模式选择")
	flow.queue_free()
	await tree.process_frame


static func _collect_label_text(node: Node) -> String:
	var result := ""
	if node is Label:
		result += (node as Label).text + "\n"
	for child in node.get_children():
		result += _collect_label_text(child)
	return result
