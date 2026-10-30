class_name CannonController
extends Node2D

signal shot_fired(player_id: int, cannon_level: int, cost: int)
signal net_opened(player_id: int, candidates: Array[FishActor], cannon: CannonDefinition, world_position: Vector2)
signal coins_changed(player_id: int, old_value: int, new_value: int)
signal pending_resolution_finished(player_id: int)

const ROTATION_SPEED_RAD := deg_to_rad(100.0)
const MIN_AIM_ANGLE := deg_to_rad(-170.0)
const MAX_AIM_ANGLE := deg_to_rad(-10.0)
const CANNON_PATHS := [
	"res://resources/data/cannons/cannon_1x.tres",
	"res://resources/data/cannons/cannon_2x.tres",
	"res://resources/data/cannons/cannon_5x.tres",
]

@export_range(1, 2, 1) var player_id: int = 1
@export var projectile_parent_path := NodePath("../../Projectiles")
@export var effects_parent_path := NodePath("../../Effects")

var player_state: PlayerState
var cannon_definitions: Array[CannonDefinition] = []
var input_enabled := true:
	set(value):
		input_enabled = value
		if not value:
			release_inputs()
var _fire_cooldown := 0.0
var _projectile_parent: Node
var _effects_parent: Node
var _keyboard_aim_axis := 0.0
var _fire_held := false


func _ready() -> void:
	if cannon_definitions.is_empty():
		for path in CANNON_PATHS:
			var definition := load(path) as CannonDefinition
			assert(definition != null, "无法加载炮台资源：%s" % path)
			cannon_definitions.append(definition)
	if player_state == null:
		player_state = PlayerState.new(player_id)
	_projectile_parent = get_node_or_null(projectile_parent_path)
	_effects_parent = get_node_or_null(effects_parent_path)
	rotation = clampf(rotation, MIN_AIM_ANGLE, MAX_AIM_ANGLE)


func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	if not input_enabled or player_state == null or player_state.is_exhausted:
		return
	if not is_zero_approx(_keyboard_aim_axis):
		rotate_aim(_keyboard_aim_axis * ROTATION_SPEED_RAD * delta)
	if _fire_held and is_zero_approx(_fire_cooldown):
		try_fire()


func configure(state: PlayerState, definitions: Array[CannonDefinition], projectile_parent: Node, effects_parent: Node) -> void:
	player_state = state
	cannon_definitions = definitions
	_projectile_parent = projectile_parent
	_effects_parent = effects_parent


func reset_for_session(state: PlayerState, projectile_parent: Node, effects_parent: Node) -> void:
	player_state = state
	_projectile_parent = projectile_parent
	_effects_parent = effects_parent
	_fire_cooldown = 0.0
	input_enabled = true
	release_inputs()


func rotate_aim(delta_radians: float) -> void:
	rotation = clampf(rotation + delta_radians, MIN_AIM_ANGLE, MAX_AIM_ANGLE)


func set_keyboard_aim_axis(_player_id: int, axis: float) -> void:
	if _player_id != player_id:
		push_error("炮台命令 player_id 不匹配")
		return
	_keyboard_aim_axis = clampf(axis, -1.0, 1.0)


func aim_at_world_position(_player_id: int, target: Vector2) -> void:
	if _player_id != player_id:
		push_error("炮台命令 player_id 不匹配")
		return
	var offset := target - global_position
	if offset.is_zero_approx():
		return
	var desired_global := offset.angle()
	if desired_global > 0.0:
		desired_global = MIN_AIM_ANGLE if offset.x < 0.0 else MAX_AIM_ANGLE
	var parent_rotation := (get_parent() as Node2D).global_rotation if get_parent() is Node2D else 0.0
	rotation = clampf(desired_global - parent_rotation, MIN_AIM_ANGLE, MAX_AIM_ANGLE)


func request_level_change(_player_id: int, delta: int) -> bool:
	if _player_id != player_id or (delta != -1 and delta != 1):
		return false
	cycle_level(delta)
	return true


func set_fire_held(_player_id: int, held: bool) -> void:
	if _player_id != player_id:
		return
	var was_held := _fire_held
	_fire_held = held and input_enabled
	if _fire_held and not was_held:
		try_fire()


func request_fire_once(_player_id: int) -> bool:
	return _player_id == player_id and try_fire()


func release_inputs() -> void:
	_keyboard_aim_axis = 0.0
	_fire_held = false


func cycle_level(direction: int) -> void:
	if cannon_definitions.is_empty() or player_state == null:
		return
	player_state.current_cannon_level = posmod(player_state.current_cannon_level + signi(direction), cannon_definitions.size())


func choose_affordable_level(requested_level: int) -> int:
	if player_state == null or cannon_definitions.is_empty():
		return -1
	var start := clampi(requested_level, 0, cannon_definitions.size() - 1)
	for index in range(start, -1, -1):
		if player_state.can_afford(cannon_definitions[index].shot_cost):
			return index
	return -1


func try_fire() -> bool:
	if not input_enabled or player_state == null or player_state.is_exhausted or _fire_cooldown > 0.0:
		return false
	var level := choose_affordable_level(player_state.current_cannon_level)
	if level < 0 or _projectile_parent == null:
		return false
	var cannon := cannon_definitions[level]
	var projectile := cannon.projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_error("炮台资源的 projectile_scene 必须实例化为 Projectile")
		return false

	var old_coins := player_state.coins
	if not player_state.spend(cannon.shot_cost):
		projectile.free()
		return false
	player_state.current_cannon_level = level
	player_state.begin_pending_resolution()
	_projectile_parent.add_child(projectile)
	projectile.global_position = $Muzzle.global_position
	projectile.configure(player_id, Vector2.RIGHT.rotated(global_rotation), cannon)
	projectile.resolution_requested.connect(_on_projectile_resolution_requested)
	_fire_cooldown = cannon.fire_interval_sec
	coins_changed.emit(player_id, old_coins, player_state.coins)
	shot_fired.emit(player_id, level, cannon.shot_cost)
	return true


func _on_projectile_resolution_requested(projectile: Projectile, hit_position: Vector2, create_net: bool) -> void:
	if create_net and _effects_parent != null:
		_create_net_deferred.call_deferred(projectile.cannon_definition, hit_position)
	else:
		finish_pending_resolution()


func _create_net_deferred(cannon: CannonDefinition, hit_position: Vector2) -> void:
	if _effects_parent == null or not is_instance_valid(_effects_parent):
		finish_pending_resolution()
		return
	var net := preload("res://scenes/game/net_effect.tscn").instantiate() as NetEffect
	_effects_parent.add_child(net)
	net.global_position = hit_position
	net.configure(player_id, cannon)
	net.candidates_found.connect(_on_net_candidates_found)


func _on_net_candidates_found(candidates: Array[FishActor], cannon: CannonDefinition, world_position: Vector2) -> void:
	net_opened.emit(player_id, candidates, cannon, world_position)
	finish_pending_resolution()


func finish_pending_resolution() -> void:
	if player_state == null:
		return
	if not player_state.finish_pending_resolution():
		push_warning("P%d 收到重复 pending 结算" % player_id)
		return
	pending_resolution_finished.emit(player_id)
