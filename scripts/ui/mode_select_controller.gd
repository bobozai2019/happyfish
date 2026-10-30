class_name ModeSelectController
extends Control

signal selection_confirmed(config: GameSessionConfig)

var _selection := GameSessionConfig.new()
var _last_single_control := GameSessionConfig.SinglePlayerControl.MOUSE

@onready var single_mode_button: Button = %SingleModeButton
@onready var coop_mode_button: Button = %CoopModeButton
@onready var control_section: Control = %ControlSection
@onready var mouse_control_button: Button = %MouseControlButton
@onready var keyboard_control_button: Button = %KeyboardControlButton
@onready var instructions: Label = %Instructions
@onready var error_label: Label = %ErrorLabel


func _ready() -> void:
	single_mode_button.pressed.connect(_select_single_player)
	coop_mode_button.pressed.connect(_select_local_coop)
	mouse_control_button.pressed.connect(_select_mouse)
	keyboard_control_button.pressed.connect(_select_keyboard)
	%StartButton.pressed.connect(_confirm_selection)
	set_selection(_selection)


func set_selection(config: GameSessionConfig) -> void:
	if config == null or not config.validate().is_empty():
		show_error("无法读取上次选择，已恢复默认设置。")
		_selection = GameSessionConfig.new()
		_last_single_control = GameSessionConfig.SinglePlayerControl.MOUSE
	else:
		_selection = config.duplicate_config()
		_last_single_control = config.single_player_control
	_refresh()


func get_selection() -> GameSessionConfig:
	return _selection.duplicate_config()


func show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = not message.is_empty()


func _select_single_player() -> void:
	_selection.game_mode = GameSessionConfig.GameMode.SINGLE_PLAYER
	_selection.single_player_control = _last_single_control
	show_error("")
	_refresh()


func _select_local_coop() -> void:
	if _selection.is_single_player():
		_last_single_control = _selection.single_player_control
	_selection.game_mode = GameSessionConfig.GameMode.LOCAL_COOP
	show_error("")
	_refresh()


func _select_mouse() -> void:
	_last_single_control = GameSessionConfig.SinglePlayerControl.MOUSE
	_selection.single_player_control = _last_single_control
	show_error("")
	_refresh()


func _select_keyboard() -> void:
	_last_single_control = GameSessionConfig.SinglePlayerControl.KEYBOARD
	_selection.single_player_control = _last_single_control
	show_error("")
	_refresh()


func _confirm_selection() -> void:
	var errors := _selection.validate()
	if not errors.is_empty():
		show_error(errors[0])
		return
	selection_confirmed.emit(_selection.duplicate_config())


func _refresh() -> void:
	var single := _selection.is_single_player()
	single_mode_button.button_pressed = single
	coop_mode_button.button_pressed = not single
	control_section.visible = single
	mouse_control_button.button_pressed = _selection.single_player_control == GameSessionConfig.SinglePlayerControl.MOUSE
	keyboard_control_button.button_pressed = _selection.single_player_control == GameSessionConfig.SinglePlayerControl.KEYBOARD
	if single and _selection.single_player_control == GameSessionConfig.SinglePlayerControl.MOUSE:
		instructions.text = "移动鼠标瞄准 · 左键开炮 · HUD 按钮换挡"
	elif single:
		instructions.text = "A / D 瞄准 · W / S 换挡 · Space 开炮"
	else:
		instructions.text = "玩家 1：A/D、W/S、Space　　玩家 2：方向键、Enter"
