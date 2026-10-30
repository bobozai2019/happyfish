extends RefCounted


static func run(tree: SceneTree, main_scene: Node) -> PackedStringArray:
	var errors := PackedStringArray()
	_test_probability_formula(errors)
	await _test_capture_and_pity(tree, errors)
	await _test_session_economy(tree, main_scene, errors)
	return errors


static func _test_probability_formula(errors: PackedStringArray) -> void:
	if not is_equal_approx(CaptureService.pity_bonus(2), 0.0):
		errors.append("保底连续空网 2 次不应有加成")
	if not is_equal_approx(CaptureService.pity_bonus(3), 0.05):
		errors.append("保底连续空网 3 次应加 5%")
	if not is_equal_approx(CaptureService.pity_bonus(5), 0.10) or not is_equal_approx(CaptureService.pity_bonus(7), 0.10):
		errors.append("保底连续空网 5 次及以上应加 10%")
	if not is_equal_approx(CaptureService.calculate_capture_chance(0.35, 4.2, 0), 0.80):
		errors.append("捕获概率必须封顶 80%")
	if not is_equal_approx(CaptureService.calculate_capture_chance(0.004, 1.0, 0), 0.01):
		errors.append("捕获概率必须保底 1%")


static func _test_capture_and_pity(tree: SceneTree, errors: PackedStringArray) -> void:
	var fixture := Node2D.new()
	tree.root.add_child(fixture)
	var service := CaptureService.new()
	fixture.add_child(service)
	var one_x := load("res://resources/data/cannons/cannon_1x.tres") as CannonDefinition

	var empty_state := PlayerState.new(1)
	empty_state.empty_net_streak = 3
	service.resolve_net(1, [], one_x, empty_state)
	if empty_state.empty_net_streak != 3:
		errors.append("没有覆盖鱼的空网不得累计或重置保底")

	var boss := _make_fish(fixture, "res://resources/data/fish/whale_shark_boss.tres", 1, Vector2.ZERO)
	var boss_state := PlayerState.new(1)
	boss_state.empty_net_streak = 7
	var miss_seed := _find_seed_above(0.104)
	service.set_rng_seed(miss_seed)
	var boss_candidates: Array[FishActor] = [boss]
	var boss_result := service.resolve_net(1, boss_candidates, one_x, boss_state)
	if not boss_result.is_empty() or boss_state.empty_net_streak != 8:
		errors.append("7 次保底不得保证捕获仅有的 Boss 候选")

	var shark := _make_fish(fixture, "res://resources/data/fish/shark.tres", 4, Vector2(20, 0))
	var clown := _make_fish(fixture, "res://resources/data/fish/clownfish.tres", 3, Vector2(40, 0))
	var puffer := _make_fish(fixture, "res://resources/data/fish/pufferfish.tres", 2, Vector2(60, 0))
	var pity_state := PlayerState.new(1)
	pity_state.empty_net_streak = 7
	service.set_rng_seed(9)
	var candidates: Array[FishActor] = [shark, clown, puffer]
	var pity_result := service.resolve_net(1, candidates, one_x, pity_state)
	if &"clownfish" not in pity_result or pity_state.empty_net_streak != 0:
		errors.append("7 次保底必须捕获价值最低的非 Boss 鱼并重置 streak")

	var contested := _make_fish(fixture, "res://resources/data/fish/clownfish.tres", 10, Vector2(80, 0))
	var first_state := PlayerState.new(1)
	var second_state := PlayerState.new(2)
	first_state.empty_net_streak = 7
	second_state.empty_net_streak = 7
	var contested_candidates: Array[FishActor] = [contested]
	var first_result := service.resolve_net(1, contested_candidates, one_x, first_state)
	var second_result := service.resolve_net(2, contested_candidates, one_x, second_state)
	if first_result.size() != 1 or not second_result.is_empty() or contested.claimed_by_player != 1:
		errors.append("竞争渔网下同一鱼最多只能归属并奖励一次")
	if second_state.empty_net_streak != 7:
		errors.append("已被其他玩家声明的鱼不应计入第二张网的有效候选")

	fixture.queue_free()
	await tree.process_frame


static func _test_session_economy(tree: SceneTree, main_scene: Node, errors: PackedStringArray) -> void:
	var session := main_scene.get_node("Session") as SessionState
	session.start_new_session()
	await tree.process_frame
	var p1 := session.get_player(1)
	var capture_service := main_scene.get_node("Session/CaptureService") as CaptureService
	var fish_parent := main_scene.get_node("World/Fish")
	var fish := _make_fish(fish_parent, "res://resources/data/fish/clownfish.tres", 100, Vector2(100, 100))
	p1.empty_net_streak = 7
	var before_coins := p1.coins
	var one_x := load("res://resources/data/cannons/cannon_1x.tres") as CannonDefinition
	var session_candidates: Array[FishActor] = [fish]
	capture_service.resolve_net(1, session_candidates, one_x, p1)
	if p1.coins != before_coins + 2 or p1.capture_count != 1 or p1.capture_value != 2 or p1.largest_capture_id != &"clownfish":
		errors.append("SessionState 必须把捕获奖励和统计归属到声明玩家")

	p1.coins = 0
	p1.pending_resolution_count = 1
	session.evaluate_player_exhaustion(1)
	if p1.coins != 0 or p1.rescue_used:
		errors.append("金币为 0 但仍有 pending 时不得触发救援")
	p1.finish_pending_resolution()
	session.evaluate_player_exhaustion(1)
	if p1.coins != 30 or not p1.rescue_used or p1.is_exhausted:
		errors.append("首次真正耗尽必须且只能救援 30 金币")
	p1.coins = 0
	session.evaluate_player_exhaustion(1)
	if not p1.is_exhausted:
		errors.append("第二次真正耗尽必须进入等待伙伴状态")

	var p2 := session.get_player(2)
	p2.coins = 0
	session.evaluate_player_exhaustion(2)
	if p2.coins != 30 or not p2.rescue_used:
		errors.append("P2 首次救援必须与 P1 独立")
	p2.coins = 0
	session.evaluate_player_exhaustion(2)
	if not p2.is_exhausted or session.state != SessionState.State.RESULTS:
		errors.append("双方真正耗尽且无 pending 后必须进入 RESULTS")

	var old_p1 := p1
	var dummy := Node2D.new()
	main_scene.get_node("World/Effects").add_child(dummy)
	session.start_new_session()
	await tree.process_frame
	if session.state != SessionState.State.RUNNING or session.get_player(1) == old_p1 or session.get_player(1).coins != 120:
		errors.append("重开必须创建全新 RUNNING 玩家状态")
	if main_scene.get_node("World/Effects").get_child_count() != 0:
		errors.append("重开必须清理旧渔网、特效与运行时节点")

	if not session.transition_to(SessionState.State.PAUSED):
		errors.append("RUNNING → PAUSED 应合法")
	if session.transition_to(SessionState.State.RESULTS):
		errors.append("PAUSED → RESULTS 必须被拒绝")
	if not session.transition_to(SessionState.State.RUNNING):
		errors.append("PAUSED → RUNNING 应合法")


static func _make_fish(parent: Node, resource_path: String, serial: int, world_position: Vector2) -> FishActor:
	var fish := (load("res://scenes/game/fish_actor.tscn") as PackedScene).instantiate() as FishActor
	var curve := Curve2D.new()
	curve.add_point(world_position)
	curve.add_point(world_position + Vector2(1000.0, 0.0))
	parent.add_child(fish)
	var definition := load(resource_path) as FishDefinition
	fish.configure(definition, curve, false, serial, definition.speed_min)
	fish.set_physics_process(false)
	fish.global_position = world_position
	return fish


static func _find_seed_above(threshold: float) -> int:
	var probe := RandomNumberGenerator.new()
	for value in range(1, 10000):
		probe.seed = value
		if probe.randf() > threshold:
			return value
	return 1
