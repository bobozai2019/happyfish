class_name GameFlowController
extends Node

signal app_state_changed(old_state: int, new_state: int)
signal game_started(config: GameSessionConfig)
signal game_returned_to_select
signal single_control_changed(old_control: int, new_control: int)

enum AppState {
	MODE_SELECT,
	PLAYING,
}

@export var battle_scene: PackedScene = preload("res://scenes/game/main.tscn")

var app_state := AppState.MODE_SELECT
var last_selection := GameSessionConfig.new()
var current_game: Node
var current_config: GameSessionConfig

@onready var mode_select: ModeSelectController = $ModeSelect
@onready var game_container: Node = $GameContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mode_select.selection_confirmed.connect(start_game)
	mode_select.set_selection(last_selection)
	mode_select.visible = true


func start_game(config: GameSessionConfig) -> bool:
	if app_state != AppState.MODE_SELECT or current_game != null:
		push_error("只有模式选择状态可以开始游戏")
		return false
	if config == null or not config.validate().is_empty():
		mode_select.show_error("游戏配置无效，请重新选择。")
		return false
	if battle_scene == null:
		mode_select.show_error("战斗场景暂时无法加载，请稍后重试。")
		return false

	var game := battle_scene.instantiate()
	if game == null:
		mode_select.show_error("战斗场景暂时无法创建，请稍后重试。")
		return false
	var session := game.get_node_or_null("Session") as SessionState
	if session == null or not session.configure(config):
		game.free()
		mode_select.show_error("战斗配置失败，请重新开始。")
		return false

	last_selection = config.duplicate_config()
	current_config = config.duplicate_config()
	current_game = game
	game_container.add_child(game)
	_connect_game_requests(game)
	mode_select.visible = false
	_set_app_state(AppState.PLAYING)
	game_started.emit(current_config.duplicate_config())
	return true


func return_to_mode_select() -> void:
	if app_state != AppState.PLAYING:
		return
	get_tree().paused = false
	if current_game != null:
		current_game.queue_free()
	current_game = null
	current_config = null
	mode_select.set_selection(last_selection)
	mode_select.visible = true
	_set_app_state(AppState.MODE_SELECT)
	game_returned_to_select.emit()


func restart_current_game() -> bool:
	if app_state != AppState.PLAYING or current_game == null or current_config == null:
		return false
	var session := current_game.get_node_or_null("Session") as SessionState
	if session == null:
		return false
	var router := current_game.get_node_or_null("InputRouter") as PlayerInputRouter
	if router != null:
		router.release_all_inputs()
	session.start_new_session()
	return true


func update_single_control(control: GameSessionConfig.SinglePlayerControl) -> bool:
	if app_state != AppState.PLAYING or current_config == null or not current_config.is_single_player():
		return false
	if control != GameSessionConfig.SinglePlayerControl.MOUSE and control != GameSessionConfig.SinglePlayerControl.KEYBOARD:
		return false
	var old_control := current_config.single_player_control
	if old_control == control:
		return true
	var router := current_game.get_node_or_null("InputRouter") as PlayerInputRouter
	if router == null or not router.set_single_control(control):
		return false
	current_config.single_player_control = control
	last_selection.single_player_control = control
	var session := current_game.get_node_or_null("Session") as SessionState
	if session != null and session.config != null:
		session.config.single_player_control = control
	var ui := current_game.get_node_or_null("UI") as UIController
	if ui != null:
		ui.apply_single_control(control)
	single_control_changed.emit(old_control, control)
	return true


func _set_app_state(new_state: AppState) -> void:
	if new_state == app_state:
		return
	var old_state := app_state
	app_state = new_state
	app_state_changed.emit(old_state, new_state)


func _connect_game_requests(game: Node) -> void:
	var ui := game.get_node_or_null("UI")
	if ui == null:
		return
	if ui.has_signal("restart_requested"):
		ui.connect("restart_requested", restart_current_game)
	if ui.has_signal("return_to_mode_select_requested"):
		ui.connect("return_to_mode_select_requested", return_to_mode_select)
	if ui.has_signal("single_control_change_requested"):
		ui.connect("single_control_change_requested", update_single_control)
