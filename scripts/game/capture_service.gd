class_name CaptureService
extends Node

signal net_resolved(player_id: int, eligible_count: int, captured_ids: Array[StringName], total_reward: int)
signal fish_captured(player_id: int, fish_id: StringName, reward: int, world_position: Vector2)

var random := RandomNumberGenerator.new()


func _ready() -> void:
	if random.seed == 0:
		random.randomize()


func set_rng_seed(value: int) -> void:
	random.seed = value


func resolve_net(player_id: int, candidates: Array[FishActor], cannon: CannonDefinition, player_state: PlayerState) -> Array[StringName]:
	var eligible: Array[FishActor] = []
	for fish in candidates:
		if is_instance_valid(fish) and fish.is_capturable() and fish.definition != null:
			eligible.append(fish)
	eligible.sort_custom(func(a: FishActor, b: FishActor) -> bool: return a.instance_serial < b.instance_serial)

	var captured_ids: Array[StringName] = []
	var total_reward := 0
	var guaranteed_fish := _find_guaranteed_fish(eligible, player_state.empty_net_streak)
	for fish in eligible:
		var should_capture := fish == guaranteed_fish
		if not should_capture:
			var chance := calculate_capture_chance(fish.definition.base_capture_chance, cannon.probability_multiplier, player_state.empty_net_streak)
			should_capture = random.randf() <= chance
		if should_capture and fish.try_claim_capture(player_id):
			captured_ids.append(fish.definition.id)
			total_reward += fish.definition.reward
			fish_captured.emit(player_id, fish.definition.id, fish.definition.reward, fish.global_position)
			fish.remove_from_play(true)

	if eligible.is_empty():
		pass
	elif captured_ids.is_empty():
		player_state.empty_net_streak += 1
	else:
		player_state.empty_net_streak = 0
	net_resolved.emit(player_id, eligible.size(), captured_ids.duplicate(), total_reward)
	return captured_ids


static func pity_bonus(empty_net_streak: int) -> float:
	if empty_net_streak >= 5:
		return 0.10
	if empty_net_streak >= 3:
		return 0.05
	return 0.0


static func calculate_capture_chance(base_chance: float, probability_multiplier: float, empty_net_streak: int) -> float:
	return clampf(base_chance * probability_multiplier + pity_bonus(empty_net_streak), 0.01, 0.80)


static func _find_guaranteed_fish(eligible: Array[FishActor], empty_net_streak: int) -> FishActor:
	if empty_net_streak < 7:
		return null
	var result: FishActor
	for fish in eligible:
		if fish.definition.is_boss:
			continue
		if result == null or fish.definition.reward < result.definition.reward or (fish.definition.reward == result.definition.reward and fish.instance_serial < result.instance_serial):
			result = fish
	return result
