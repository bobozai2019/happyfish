extends RefCounted


static func run(tree: SceneTree, main_scene: Node) -> PackedStringArray:
	var errors := PackedStringArray()
	await _test_cannon_and_projectile(tree, errors)
	_test_atomic_fish_claim(errors)
	await _test_net_radius_query(tree, errors)
	await _test_main_scene_spawning(tree, main_scene, errors)
	return errors


static func _test_cannon_and_projectile(tree: SceneTree, errors: PackedStringArray) -> void:
	var fixture := Node2D.new()
	fixture.name = "CannonFixture"
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	var effects := Node2D.new()
	effects.name = "Effects"
	fixture.add_child(projectiles)
	fixture.add_child(effects)
	tree.root.add_child(fixture)

	var cannon_scene := load("res://scenes/game/cannon.tscn") as PackedScene
	var cannon := cannon_scene.instantiate() as CannonController
	fixture.add_child(cannon)
	await tree.process_frame

	var definitions: Array[CannonDefinition] = [
		load("res://resources/data/cannons/cannon_1x.tres") as CannonDefinition,
		load("res://resources/data/cannons/cannon_2x.tres") as CannonDefinition,
		load("res://resources/data/cannons/cannon_5x.tres") as CannonDefinition,
	]
	var state := PlayerState.new(1)
	state.coins = 2
	state.current_cannon_level = 2
	cannon.configure(state, definitions, projectiles, effects)
	cannon.rotation = -PI * 0.5
	if not cannon.try_fire():
		errors.append("CannonController 应在 5× 不可支付时自动降为 2× 并发射")
	elif state.coins != 0 or state.current_cannon_level != 1 or state.pending_resolution_count != 1:
		errors.append("CannonController 降档扣费或 pending 递增错误")
	if projectiles.get_child_count() != 1:
		errors.append("成功发射必须且只能生成一个 Projectile")
	else:
		var projectile := projectiles.get_child(0) as Projectile
		if projectile == null or not projectile.resolve_once(false):
			errors.append("Projectile 首次出界结算失败")
		elif state.pending_resolution_count != 0:
			errors.append("Projectile 完成后 pending 未归零")
		elif projectile.resolve_once(false):
			errors.append("Projectile 不得重复结算")

	cannon.rotation = -PI * 0.5
	cannon.rotate_aim(-TAU)
	if not is_equal_approx(cannon.rotation, CannonController.MIN_AIM_ANGLE):
		errors.append("炮台逆时针旋转未限制在上半区")
	cannon.rotate_aim(TAU * 2.0)
	if not is_equal_approx(cannon.rotation, CannonController.MAX_AIM_ANGLE):
		errors.append("炮台顺时针旋转未限制在上半区")

	fixture.queue_free()
	await tree.process_frame


static func _test_atomic_fish_claim(errors: PackedStringArray) -> void:
	var packed := load("res://scenes/game/fish_actor.tscn") as PackedScene
	var fish := packed.instantiate() as FishActor
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(200.0, 0.0))
	var definition := load("res://resources/data/fish/clownfish.tres") as FishDefinition
	fish.configure(definition, curve, false, 42, 100.0)
	if not fish.try_claim_capture(1):
		errors.append("FishActor 首次原子捕获声明应成功")
	if fish.try_claim_capture(2) or fish.claimed_by_player != 1:
		errors.append("FishActor 已声明后不得被第二位玩家重复领取")
	fish.remove_from_play(true)
	fish.free()


static func _test_net_radius_query(tree: SceneTree, errors: PackedStringArray) -> void:
	var fixture := Node2D.new()
	tree.root.add_child(fixture)
	var fish := (load("res://scenes/game/fish_actor.tscn") as PackedScene).instantiate() as FishActor
	var curve := Curve2D.new()
	curve.add_point(Vector2.ZERO)
	curve.add_point(Vector2(1000.0, 0.0))
	var definition := load("res://resources/data/fish/clownfish.tres") as FishDefinition
	fixture.add_child(fish)
	fish.configure(definition, curve, false, 77, 1.0)
	fish.set_physics_process(false)
	fish.position = Vector2(115.0, 0.0)
	await tree.physics_frame

	var one_x := load("res://resources/data/cannons/cannon_1x.tres") as CannonDefinition
	var five_x := load("res://resources/data/cannons/cannon_5x.tres") as CannonDefinition
	var small_result: Array[FishActor] = []
	var small_net := (load("res://scenes/game/net_effect.tscn") as PackedScene).instantiate() as NetEffect
	fixture.add_child(small_net)
	small_net.configure(1, one_x)
	small_net.candidates_found.connect(func(candidates: Array[FishActor], _cannon: CannonDefinition, _position: Vector2) -> void: small_result.assign(candidates))
	await tree.physics_frame
	await tree.physics_frame
	if not small_result.is_empty():
		errors.append("1× 渔网半径 72 不应与中心距 115px 的鱼相交")

	var large_result: Array[FishActor] = []
	var large_net := (load("res://scenes/game/net_effect.tscn") as PackedScene).instantiate() as NetEffect
	fixture.add_child(large_net)
	large_net.configure(1, five_x)
	large_net.candidates_found.connect(func(candidates: Array[FishActor], _cannon: CannonDefinition, _position: Vector2) -> void: large_result.assign(candidates))
	await tree.physics_frame
	await tree.physics_frame
	if large_result.size() != 1 or large_result[0] != fish:
		errors.append("5× 渔网半径 104 应与中心距 115px 的鱼相交")

	fixture.queue_free()
	await tree.process_frame


static func _test_main_scene_spawning(tree: SceneTree, main_scene: Node, errors: PackedStringArray) -> void:
	var p1 := main_scene.get_node_or_null("World/Cannons/P1Cannon") as CannonController
	var p2 := main_scene.get_node_or_null("World/Cannons/P2Cannon") as CannonController
	if p1 == null or p2 == null:
		errors.append("主场景必须静态实例化两座炮台")
	else:
		if p1.player_state == p2.player_state or p1.player_state.player_id != 1 or p2.player_state.player_id != 2:
			errors.append("两座炮台必须使用独立 PlayerState")
		var p1_rotation_before := p1.rotation
		var p2_rotation_before := p2.rotation
		Input.action_press(&"p1_aim_left")
		Input.action_press(&"p2_aim_right")
		await tree.physics_frame
		await tree.physics_frame
		var observed_p1_axis := Input.get_axis("p1_aim_left", "p1_aim_right")
		var observed_p2_axis := Input.get_axis("p2_aim_left", "p2_aim_right")
		Input.action_release(&"p1_aim_left")
		Input.action_release(&"p2_aim_right")
		if p1.rotation >= p1_rotation_before or p2.rotation <= p2_rotation_before:
			var router := main_scene.get_node("InputRouter") as PlayerInputRouter
			errors.append("两套瞄准输入必须在同一帧独立控制对应炮台（P1 %.3f→%.3f，P2 %.3f→%.3f，router=%s，cannons=%d，axis=%.1f/%.1f，command=%.1f/%.1f，enabled=%s/%s）" % [p1_rotation_before, p1.rotation, p2_rotation_before, p2.rotation, router.enabled, router.cannons.size(), observed_p1_axis, observed_p2_axis, p1._keyboard_aim_axis, p2._keyboard_aim_axis, p1.input_enabled, p2.input_enabled])

		Input.action_press(&"p1_level_up")
		Input.action_press(&"p2_level_down")
		await tree.physics_frame
		await tree.physics_frame
		Input.action_release(&"p1_level_up")
		Input.action_release(&"p2_level_down")
		if p1.player_state.current_cannon_level != 1 or p2.player_state.current_cannon_level != 2:
			errors.append("两套倍率输入必须独立切换 1×/2×/5×")

		var p1_shots := [0]
		var p2_shots := [0]
		p1.shot_fired.connect(func(_player_id: int, _level: int, _cost: int) -> void: p1_shots[0] += 1)
		p2.shot_fired.connect(func(_player_id: int, _level: int, _cost: int) -> void: p2_shots[0] += 1)
		Input.action_press(&"p1_fire")
		Input.action_press(&"p2_fire")
		for frame in range(35):
			await tree.physics_frame
		Input.action_release(&"p1_fire")
		Input.action_release(&"p2_fire")
		if p1_shots[0] < 2 or p2_shots[0] < 2:
			errors.append("按下应立即发射且按住应按 0.25 秒独立连发")
		for projectile in main_scene.get_node("World/Projectiles").get_children():
			(projectile as Projectile).resolve_once(false)
		for frame in range(3):
			await tree.physics_frame
		if p1.player_state.pending_resolution_count != 0 or p2.player_state.pending_resolution_count != 0:
			errors.append("双炮台 pending 生命周期必须彼此独立并最终归零")

	var director := main_scene.get_node_or_null("World/SpawnDirector") as SpawnDirector
	if director == null:
		errors.append("主场景缺少 SpawnDirector")
		return
	for frame in range(70):
		await tree.physics_frame
	if director.active_fish.is_empty():
		errors.append("SpawnDirector 未在 0.55-1.0 秒窗口生成普通鱼")
	if director.get_ordinary_count() > SpawnDirector.MAX_ORDINARY_FISH:
		errors.append("SpawnDirector 普通鱼数量超过 20")

	var elapsed_before_pause := director.elapsed_time
	tree.paused = true
	for frame in range(10):
		await tree.process_frame
	tree.paused = false
	if not is_equal_approx(director.elapsed_time, elapsed_before_pause):
		errors.append("暂停期间 SpawnDirector 计时不应推进")

	director.set_total_captures(18)
	await tree.process_frame
	if director.boss_state != SpawnDirector.BossState.WARNING:
		errors.append("合计捕获 18 条应触发 Boss 警告")
	director.advance_schedule(SpawnDirector.BOSS_WARNING_DURATION)
	await tree.process_frame
	var bosses: Array[FishActor] = []
	for fish in director.active_fish:
		if is_instance_valid(fish) and fish.definition != null and fish.definition.is_boss:
			bosses.append(fish)
	if bosses.size() != 1 or director.boss_state != SpawnDirector.BossState.ACTIVE:
		errors.append("Boss 警告 2 秒后必须生成且场上最多一个 Boss")
	else:
		bosses[0].remove_from_play(false)
		await tree.process_frame
		if director.boss_state != SpawnDirector.BossState.COOLDOWN or director.boss_cooldown_remaining < 89.9:
			errors.append("Boss 离场后必须进入 90 秒冷却")
