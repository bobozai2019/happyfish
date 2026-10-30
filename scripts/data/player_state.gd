class_name PlayerState
extends RefCounted

const INITIAL_COINS := 120

var player_id: int:
	get:
		return _player_id

var coins: int = INITIAL_COINS:
	set(value):
		coins = maxi(value, 0)
var current_cannon_level: int = 0:
	set(value):
		current_cannon_level = maxi(value, 0)
var rescue_used: bool = false
var is_exhausted: bool = false
var empty_net_streak: int = 0:
	set(value):
		empty_net_streak = maxi(value, 0)
var capture_count: int = 0:
	set(value):
		capture_count = maxi(value, 0)
var capture_value: int = 0:
	set(value):
		capture_value = maxi(value, 0)
var largest_capture_id: StringName
var largest_capture_value: int = 0:
	set(value):
		largest_capture_value = maxi(value, 0)
var pending_resolution_count: int = 0:
	set(value):
		pending_resolution_count = maxi(value, 0)

var _player_id: int


func _init(new_player_id: int = 1) -> void:
	assert(new_player_id == 1 or new_player_id == 2, "player_id 只能是 1 或 2")
	_player_id = new_player_id


func can_afford(cost: int) -> bool:
	return cost > 0 and coins >= cost


func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	coins -= cost
	return true


func begin_pending_resolution() -> void:
	pending_resolution_count += 1


func finish_pending_resolution() -> bool:
	if pending_resolution_count == 0:
		return false
	pending_resolution_count -= 1
	return true


func record_capture(fish_id: StringName, reward: int) -> void:
	assert(not fish_id.is_empty(), "fish_id 不能为空")
	assert(reward > 0, "reward 必须大于 0")
	coins += reward
	capture_count += 1
	capture_value += reward
	empty_net_streak = 0
	if reward > largest_capture_value:
		largest_capture_id = fish_id
		largest_capture_value = reward
