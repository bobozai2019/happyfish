class_name PlayerInputRouter
extends Node

signal level_changed(player_id: int, cannon_level: int)

@export var session_path := NodePath("../Session")
@export var p1_cannon_path := NodePath("../World/Cannons/P1Cannon")
@export var p2_cannon_path := NodePath("../World/Cannons/P2Cannon")
@export var ui_path := NodePath("../UI")

var config: GameSessionConfig
var enabled := false
var cannons: Dictionary[int, CannonController] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var session := get_node(session_path) as SessionState
	var available: Dictionary[int, CannonController] = {}
	for player_id in session.get_active_player_ids():
		available[player_id] = get_node(p1_cannon_path if player_id == 1 else p2_cannon_path) as CannonController
	if not configure(session.config, available):
		return
	session.session_state_changed.connect(_on_session_state_changed)
	var ui := get_node_or_null(ui_path) as UIController
	if ui != null:
		ui.level_change_requested.connect(request_level_change)
		ui.fire_button_changed.connect(set_fire_button)
	set_enabled(session.state == SessionState.State.RUNNING)


func _physics_process(_delta: float) -> void:
	if not enabled or config == null:
		return
	for player_id in config.get_active_player_ids():
		if config.uses_mouse(player_id):
			continue
		var prefix := "p%d_" % player_id
		var cannon := cannons[player_id]
		cannon.set_keyboard_aim_axis(player_id, Input.get_axis(prefix + "aim_left", prefix + "aim_right"))
		if Input.is_action_just_pressed(prefix + "level_up"):
			request_level_change(player_id, 1)
		if Input.is_action_just_pressed(prefix + "level_down"):
			request_level_change(player_id, -1)
		cannon.set_fire_held(player_id, Input.is_action_pressed(prefix + "fire"))


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or config == null or not config.uses_mouse(1):
		return
	var cannon := cannons.get(1) as CannonController
	if cannon == null:
		return
	if event is InputEventMouseMotion:
		cannon.aim_at_world_position(1, _viewport_to_world(cannon, event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cannon.aim_at_world_position(1, _viewport_to_world(cannon, event.position))
		cannon.set_fire_held(1, true)
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		var cannon := cannons.get(1) as CannonController
		if cannon != null:
			cannon.set_fire_held(1, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		release_all_inputs()


func _exit_tree() -> void:
	release_all_inputs()


func configure(new_config: GameSessionConfig, new_cannons: Dictionary[int, CannonController]) -> bool:
	set_enabled(false)
	if new_config == null or not new_config.validate().is_empty():
		push_error("PlayerInputRouter 收到无效配置")
		return false
	var active_ids := new_config.get_active_player_ids()
	if new_cannons.size() != active_ids.size():
		push_error("PlayerInputRouter 炮台集合必须与 active players 一致")
		return false
	for player_id in active_ids:
		if not new_cannons.has(player_id) or new_cannons[player_id] == null:
			push_error("PlayerInputRouter 缺少 active cannon：P%d" % player_id)
			return false
	config = new_config.duplicate_config()
	cannons = new_cannons.duplicate()
	return true


func set_enabled(value: bool) -> void:
	if not value:
		release_all_inputs()
	enabled = value and config != null
	for cannon in cannons.values():
		(cannon as CannonController).input_enabled = enabled


func set_single_control(control: GameSessionConfig.SinglePlayerControl) -> bool:
	if config == null or not config.is_single_player():
		return false
	if control != GameSessionConfig.SinglePlayerControl.MOUSE and control != GameSessionConfig.SinglePlayerControl.KEYBOARD:
		return false
	release_all_inputs()
	config.single_player_control = control
	return true


func release_all_inputs() -> void:
	for cannon in cannons.values():
		(cannon as CannonController).release_inputs()


func request_level_change(player_id: int, delta: int) -> bool:
	var cannon := cannons.get(player_id) as CannonController
	if cannon == null or not cannon.request_level_change(player_id, delta):
		return false
	level_changed.emit(player_id, cannon.player_state.current_cannon_level)
	return true


func set_fire_button(player_id: int, pressed: bool) -> void:
	var cannon := cannons.get(player_id) as CannonController
	if cannon != null and enabled:
		cannon.set_fire_held(player_id, pressed)


func _on_session_state_changed(_old_state: int, new_state: int) -> void:
	set_enabled(new_state == SessionState.State.RUNNING)


func _viewport_to_world(cannon: CannonController, viewport_position: Vector2) -> Vector2:
	return cannon.get_canvas_transform().affine_inverse() * viewport_position
