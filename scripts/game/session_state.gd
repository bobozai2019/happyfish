class_name SessionState
extends Node

signal shot_fired(player_id: int, cannon_level: int, cost: int)
signal net_resolved(player_id: int, eligible_count: int, captured_ids: Array[StringName], total_reward: int)
signal fish_captured(player_id: int, fish_id: StringName, reward: int, world_position: Vector2)
signal coins_changed(player_id: int, old_value: int, new_value: int)
signal player_exhausted(player_id: int)
signal player_rescued(player_id: int, amount: int)
signal session_state_changed(old_state: int, new_state: int)

enum State { RUNNING, PAUSED, RESULTS }

const RESCUE_COINS := 30
const SINGLE_CANNON_POSITION := Vector2(640.0, 670.0)
const P1_COOP_CANNON_POSITION := Vector2(256.0, 670.0)
const P2_COOP_CANNON_POSITION := Vector2(1024.0, 670.0)

@export var p1_cannon_path := NodePath("../World/Cannons/P1Cannon")
@export var p2_cannon_path := NodePath("../World/Cannons/P2Cannon")
@export var projectiles_path := NodePath("../World/Projectiles")
@export var effects_path := NodePath("../World/Effects")
@export var fish_path := NodePath("../World/Fish")
@export var spawn_director_path := NodePath("../World/SpawnDirector")

var players: Dictionary[int, PlayerState] = {}
var state := State.RUNNING
var config: GameSessionConfig
var _cannons: Dictionary[int, CannonController] = {}
var _capture_service: CaptureService
var _spawn_director: SpawnDirector
var _ready_started := false


func _init() -> void:
	config = GameSessionConfig.new()
	config.game_mode = GameSessionConfig.GameMode.LOCAL_COOP


func _ready() -> void:
	_ready_started = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	_capture_service = $CaptureService
	_spawn_director = get_node(spawn_director_path) as SpawnDirector
	_cannons[1] = get_node(p1_cannon_path) as CannonController
	_cannons[2] = get_node(p2_cannon_path) as CannonController
	_capture_service.fish_captured.connect(_on_fish_captured)
	_capture_service.net_resolved.connect(_on_net_resolved)
	_configure_cannons_for_mode()
	if not _spawn_director.configure(10 if config.is_single_player() else 18):
		push_error("无法配置当前模式的 Boss 捕获阈值")
	for player_id in get_active_player_ids():
		var cannon := _cannons[player_id]
		cannon.shot_fired.connect(_on_shot_fired)
		cannon.net_opened.connect(_on_net_opened)
		cannon.coins_changed.connect(_on_cannon_coins_changed)
		cannon.pending_resolution_finished.connect(_on_pending_resolution_finished)
	start_new_session()


func configure(new_config: GameSessionConfig) -> bool:
	if _ready_started or new_config == null or not new_config.validate().is_empty():
		push_error("SessionState 必须在进入 SceneTree 前接收合法配置")
		return false
	config = new_config.duplicate_config()
	return true


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"pause_game"):
		if state == State.RUNNING:
			transition_to(State.PAUSED)
		elif state == State.PAUSED:
			transition_to(State.RUNNING)
	if state == State.RESULTS and Input.is_action_just_pressed(&"restart_game"):
		start_new_session()


func get_player(player_id: int) -> PlayerState:
	return players.get(player_id) as PlayerState


func get_active_player_ids() -> Array[int]:
	return config.get_active_player_ids() if config != null else []


func get_active_players() -> Array[PlayerState]:
	var result: Array[PlayerState] = []
	for player_id in get_active_player_ids():
		var player := get_player(player_id)
		if player != null:
			result.append(player)
	return result


func is_player_active(player_id: int) -> bool:
	return player_id in get_active_player_ids()


func transition_to(new_state: State) -> bool:
	if new_state == state:
		return true
	var legal := (
		(state == State.RUNNING and new_state in [State.PAUSED, State.RESULTS])
		or (state == State.PAUSED and new_state == State.RUNNING)
		or (state == State.RESULTS and new_state == State.RUNNING)
	)
	if not legal:
		return false
	var old_state := state
	state = new_state
	get_tree().paused = state == State.PAUSED
	for player_id in _cannons:
		(_cannons[player_id] as CannonController).input_enabled = state == State.RUNNING and is_player_active(player_id)
	if _spawn_director != null:
		_spawn_director.set_process(state == State.RUNNING)
	session_state_changed.emit(old_state, state)
	return true


func start_new_session() -> void:
	get_tree().paused = false
	_clear_runtime_nodes()
	if _spawn_director != null:
		_spawn_director.reset_session()
		_spawn_director.set_process(true)
	players.clear()
	for player_id in get_active_player_ids():
		players[player_id] = PlayerState.new(player_id)
	var projectile_parent := get_node(projectiles_path)
	var effects_parent := get_node(effects_path)
	for player_id in get_active_player_ids():
		var cannon := _cannons[player_id]
		cannon.reset_for_session(players[player_id], projectile_parent, effects_parent)
	if state != State.RUNNING:
		transition_to(State.RUNNING)


func evaluate_player_exhaustion(player_id: int) -> void:
	if not is_player_active(player_id):
		return
	var player := get_player(player_id)
	if player == null or player.coins > 0 or player.pending_resolution_count > 0 or player.is_exhausted:
		return
	if not player.rescue_used:
		var old_coins := player.coins
		player.rescue_used = true
		player.coins += RESCUE_COINS
		coins_changed.emit(player_id, old_coins, player.coins)
		player_rescued.emit(player_id, RESCUE_COINS)
	else:
		player.is_exhausted = true
		_cannons[player_id].input_enabled = false
		player_exhausted.emit(player_id)
	_evaluate_results()


func _on_net_opened(player_id: int, candidates: Array[FishActor], cannon: CannonDefinition, _world_position: Vector2) -> void:
	if state != State.RUNNING:
		return
	_capture_service.resolve_net(player_id, candidates, cannon, get_player(player_id))


func _on_fish_captured(player_id: int, fish_id: StringName, reward: int, world_position: Vector2) -> void:
	var player := get_player(player_id)
	var old_coins := player.coins
	player.record_capture(fish_id, reward)
	coins_changed.emit(player_id, old_coins, player.coins)
	fish_captured.emit(player_id, fish_id, reward, world_position)
	var total_captures := 0
	for active_player in get_active_players():
		total_captures += active_player.capture_count
	_spawn_director.set_total_captures(total_captures)


func _on_net_resolved(player_id: int, eligible_count: int, captured_ids: Array[StringName], total_reward: int) -> void:
	net_resolved.emit(player_id, eligible_count, captured_ids.duplicate(), total_reward)


func _on_shot_fired(player_id: int, cannon_level: int, cost: int) -> void:
	shot_fired.emit(player_id, cannon_level, cost)


func _on_cannon_coins_changed(player_id: int, old_value: int, new_value: int) -> void:
	coins_changed.emit(player_id, old_value, new_value)


func _on_pending_resolution_finished(player_id: int) -> void:
	evaluate_player_exhaustion(player_id)


func _evaluate_results() -> void:
	var active_players := get_active_players()
	if active_players.is_empty():
		return
	for player in active_players:
		if not player.is_exhausted or player.pending_resolution_count != 0:
			return
	if state != State.RESULTS:
		transition_to(State.RESULTS)


func _configure_cannons_for_mode() -> void:
	var p1 := _cannons[1]
	var p2 := _cannons[2]
	p1.position = SINGLE_CANNON_POSITION if config.is_single_player() else P1_COOP_CANNON_POSITION
	p1.visible = true
	p1.process_mode = Node.PROCESS_MODE_INHERIT
	p1.input_enabled = true
	p2.position = P2_COOP_CANNON_POSITION
	p2.visible = not config.is_single_player()
	p2.process_mode = Node.PROCESS_MODE_DISABLED if config.is_single_player() else Node.PROCESS_MODE_INHERIT
	p2.input_enabled = not config.is_single_player()


func _clear_runtime_nodes() -> void:
	for path in [projectiles_path, effects_path, fish_path]:
		var parent := get_node_or_null(path)
		if parent == null:
			continue
		for child in parent.get_children():
			child.queue_free()
