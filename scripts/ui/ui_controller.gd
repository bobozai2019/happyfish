class_name UIController
extends CanvasLayer

signal ui_button_pressed
signal restart_requested
signal return_to_mode_select_requested
signal single_control_change_requested(control: int)
signal level_change_requested(player_id: int, delta: int)
signal fire_button_changed(player_id: int, pressed: bool)

enum ConfirmationAction { NONE, RESTART, RETURN_TO_SELECT }

@export var session_path := NodePath("../Session")
@export var spawn_director_path := NodePath("../World/SpawnDirector")
@export var input_router_path := NodePath("../InputRouter")

var session: SessionState
var spawn_director: SpawnDirector
var _confirmation_action := ConfirmationAction.NONE

@onready var hud: Control = $HUDRoot
@onready var pause_layer: Control = $PauseLayer
@onready var results_layer: Control = $ResultsLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	session = get_node(session_path) as SessionState
	spawn_director = get_node(spawn_director_path) as SpawnDirector
	var input_router := get_node(input_router_path) as PlayerInputRouter
	session.coins_changed.connect(_on_coins_changed)
	session.shot_fired.connect(_on_shot_fired)
	session.fish_captured.connect(_on_fish_captured)
	session.player_rescued.connect(_on_player_rescued)
	session.player_exhausted.connect(_on_player_exhausted)
	session.session_state_changed.connect(_on_session_state_changed)
	spawn_director.boss_warning_started.connect(_on_boss_warning_started)
	spawn_director.boss_spawned.connect(_on_boss_spawned)
	input_router.level_changed.connect(_update_level)
	$HUDRoot/PauseButton.pressed.connect(_on_pause_pressed)
	$PauseLayer/CenterPanel/Layout/ContinueButton.pressed.connect(_on_continue_pressed)
	$PauseLayer/CenterPanel/Layout/RestartButton.pressed.connect(_show_restart_confirmation)
	$PauseLayer/CenterPanel/Layout/ReturnSelectButton.pressed.connect(_show_return_confirmation)
	$PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/MouseControlButton.pressed.connect(func() -> void: single_control_change_requested.emit(GameSessionConfig.SinglePlayerControl.MOUSE))
	$PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/KeyboardControlButton.pressed.connect(func() -> void: single_control_change_requested.emit(GameSessionConfig.SinglePlayerControl.KEYBOARD))
	$PauseLayer/ConfirmPanel/Layout/Buttons/ConfirmButton.pressed.connect(_confirm_pending_action)
	$PauseLayer/ConfirmPanel/Layout/Buttons/CancelButton.pressed.connect(_hide_restart_confirmation)
	$ResultsLayer/CenterPanel/Layout/RestartButton.pressed.connect(func() -> void: restart_requested.emit())
	$ResultsLayer/CenterPanel/Layout/ReturnSelectButton.pressed.connect(func() -> void: return_to_mode_select_requested.emit())
	$HUDRoot/SingleMouseControls/LevelDownButton.pressed.connect(func() -> void: _request_level_change(-1))
	$HUDRoot/SingleMouseControls/LevelUpButton.pressed.connect(func() -> void: _request_level_change(1))
	$HUDRoot/SingleMouseControls/FireButton.button_down.connect(_on_fire_button_down)
	$HUDRoot/SingleMouseControls/FireButton.button_up.connect(_on_fire_button_up)
	for button in [
		$HUDRoot/PauseButton,
		$PauseLayer/CenterPanel/Layout/ContinueButton,
		$PauseLayer/CenterPanel/Layout/RestartButton,
		$PauseLayer/CenterPanel/Layout/ReturnSelectButton,
		$PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/MouseControlButton,
		$PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/KeyboardControlButton,
		$PauseLayer/ConfirmPanel/Layout/Buttons/ConfirmButton,
		$PauseLayer/ConfirmPanel/Layout/Buttons/CancelButton,
		$ResultsLayer/CenterPanel/Layout/RestartButton,
		$ResultsLayer/CenterPanel/Layout/ReturnSelectButton,
		$HUDRoot/SingleMouseControls/LevelDownButton,
		$HUDRoot/SingleMouseControls/LevelUpButton,
		$HUDRoot/SingleMouseControls/FireButton,
	]:
		(button as Button).pressed.connect(func() -> void: ui_button_pressed.emit())
	$HUDRoot/MessageTimer.timeout.connect(_hide_message)
	refresh_all()


func refresh_all() -> void:
	for player_id in [1, 2]:
		var panel := hud.get_node("P%dPanel" % player_id) as Control
		panel.visible = session.is_player_active(player_id)
		var result_label := results_layer.get_node("CenterPanel/Layout/P%dStats" % player_id) as Label
		result_label.visible = session.is_player_active(player_id)
		if not result_label.visible:
			result_label.text = ""
	for player_id in session.get_active_player_ids():
		var player := session.get_player(player_id)
		_on_coins_changed(player_id, player.coins, player.coins)
		_update_level(player_id, player.current_cannon_level)
	pause_layer.visible = session.state == SessionState.State.PAUSED
	results_layer.visible = session.state == SessionState.State.RESULTS
	apply_single_control(session.config.single_player_control)


func _on_coins_changed(player_id: int, _old_value: int, new_value: int) -> void:
	var label := hud.get_node("P%dPanel/Layout/Coins" % player_id) as Label
	label.text = "金币  %d" % new_value


func _on_shot_fired(player_id: int, cannon_level: int, _cost: int) -> void:
	_update_level(player_id, cannon_level)


func _update_level(player_id: int, cannon_level: int) -> void:
	var multipliers := [1, 2, 5]
	var label := hud.get_node("P%dPanel/Layout/Multiplier" % player_id) as Label
	label.text = "炮倍  %d×" % multipliers[clampi(cannon_level, 0, 2)]


func _on_fish_captured(player_id: int, fish_id: StringName, reward: int, _world_position: Vector2) -> void:
	_show_message("玩家 %d 捕获 %s  +%d 金币！" % [player_id, _fish_display_name(fish_id), reward])


func _on_player_rescued(player_id: int, amount: int) -> void:
	_show_message("玩家 %d 获得救援金币 +%d！" % [player_id, amount], 2.4)


func _on_player_exhausted(player_id: int) -> void:
	var status := hud.get_node("P%dPanel/Layout/Status" % player_id) as Label
	if session.config.is_single_player():
		status.text = "本局结束 ★"
	else:
		status.text = "正在等待伙伴 ★"
		_show_message("玩家 %d 正在为伙伴加油！" % player_id, 2.4)


func _on_boss_warning_started() -> void:
	_show_message("巨大的鲸鲨正在靠近！", 2.0)


func _on_boss_spawned() -> void:
	_show_message("鲸鲨 Boss 登场！一起试试好运吧！", 2.4)


func _show_message(message: String, duration := 1.4) -> void:
	var banner := hud.get_node("MessageBanner") as PanelContainer
	var label := banner.get_node("Text") as Label
	label.text = message
	banner.visible = true
	var timer := hud.get_node("MessageTimer") as Timer
	timer.start(duration)


func _hide_message() -> void:
	hud.get_node("MessageBanner").visible = false


func _on_session_state_changed(_old_state: int, new_state: int) -> void:
	pause_layer.visible = new_state == SessionState.State.PAUSED
	results_layer.visible = new_state == SessionState.State.RESULTS
	if new_state == SessionState.State.RESULTS:
		_update_results()
	if new_state == SessionState.State.PAUSED:
		apply_single_control(session.config.single_player_control)
	if new_state == SessionState.State.RUNNING:
		_hide_restart_confirmation()
		refresh_all()


func _update_results() -> void:
	(results_layer.get_node("CenterPanel/Layout/Subtitle") as Label).text = "你的本局收获" if session.config.is_single_player() else "两位捕鱼搭档的收获"
	for player_id in session.get_active_player_ids():
		var player := session.get_player(player_id)
		var largest := "暂无" if player.largest_capture_id.is_empty() else _fish_display_name(player.largest_capture_id)
		var label := results_layer.get_node("CenterPanel/Layout/P%dStats" % player_id) as Label
		label.text = "玩家 %d\n捕获 %d 条　总价值 %d\n最大鱼：%s" % [player_id, player.capture_count, player.capture_value, largest]


func _on_pause_pressed() -> void:
	if session.state == SessionState.State.RUNNING:
		session.transition_to(SessionState.State.PAUSED)


func _on_continue_pressed() -> void:
	if session.state == SessionState.State.PAUSED:
		session.transition_to(SessionState.State.RUNNING)


func _show_restart_confirmation() -> void:
	_confirmation_action = ConfirmationAction.RESTART
	($PauseLayer/ConfirmPanel/Layout/Question as Label).text = "确认开始全新一局吗？"
	($PauseLayer/ConfirmPanel/Layout/Buttons/ConfirmButton as Button).text = "确认重开"
	$PauseLayer/ConfirmPanel.visible = true
	$PauseLayer/CenterPanel.visible = false


func _show_return_confirmation() -> void:
	_confirmation_action = ConfirmationAction.RETURN_TO_SELECT
	($PauseLayer/ConfirmPanel/Layout/Question as Label).text = "返回模式选择并结束本局吗？"
	($PauseLayer/ConfirmPanel/Layout/Buttons/ConfirmButton as Button).text = "确认返回"
	$PauseLayer/ConfirmPanel.visible = true
	$PauseLayer/CenterPanel.visible = false


func _hide_restart_confirmation() -> void:
	_confirmation_action = ConfirmationAction.NONE
	$PauseLayer/ConfirmPanel.visible = false
	$PauseLayer/CenterPanel.visible = true


func _confirm_pending_action() -> void:
	var action := _confirmation_action
	_hide_restart_confirmation()
	if action == ConfirmationAction.RESTART:
		restart_requested.emit()
	elif action == ConfirmationAction.RETURN_TO_SELECT:
		return_to_mode_select_requested.emit()


func apply_single_control(control: GameSessionConfig.SinglePlayerControl) -> void:
	var single := session.config.is_single_player()
	var mouse_mode := single and control == GameSessionConfig.SinglePlayerControl.MOUSE
	$HUDRoot/SingleMouseControls.visible = mouse_mode
	($HUDRoot/P1Panel/Layout/Title as Label).text = "玩家 1  ★ 暖阳炮台" if not single else "单人玩家  ★ 暖阳炮台"
	($HUDRoot/P1Panel/Layout/Controls as Label).text = "鼠标瞄准　左键 / 按钮开炮" if mouse_mode else "A / D 瞄准　W / S 换档　Space 开炮"
	var control_section := $PauseLayer/CenterPanel/Layout/ControlSection as Control
	control_section.visible = single
	if single:
		($PauseLayer/CenterPanel/Layout/Hint as Label).text = "休息一下，也可以即时切换操作方式。"
		($PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/MouseControlButton as Button).button_pressed = mouse_mode
		($PauseLayer/CenterPanel/Layout/ControlSection/ControlButtons/KeyboardControlButton as Button).button_pressed = not mouse_mode
		($PauseLayer/CenterPanel/Layout/ControlSection/ControlHint as Label).text = "鼠标瞄准 · 左键或按钮开炮" if mouse_mode else "A/D 瞄准 · W/S 换挡 · Space 开炮"
	else:
		($PauseLayer/CenterPanel/Layout/Hint as Label).text = "双人模式固定使用两套键盘操作。"


func _on_fire_button_down() -> void:
	var button := $HUDRoot/SingleMouseControls/FireButton as Button
	button.modulate = Color(1.2, 1.2, 0.8, 1.0)
	fire_button_changed.emit(1, true)


func _request_level_change(delta: int) -> void:
	level_change_requested.emit(1, delta)


func _on_fire_button_up() -> void:
	var button := $HUDRoot/SingleMouseControls/FireButton as Button
	button.modulate = Color.WHITE
	fire_button_changed.emit(1, false)


func _fish_display_name(fish_id: StringName) -> String:
	var path := "res://resources/data/fish/%s.tres" % fish_id
	var definition := load(path) as FishDefinition
	return definition.display_name if definition != null else String(fish_id)
