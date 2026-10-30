class_name SpawnDirector
extends Node

signal boss_warning_started
signal boss_spawned

enum BossState { READY, WARNING, ACTIVE, COOLDOWN }

const MAX_ORDINARY_FISH := 20
const MIN_SPAWN_INTERVAL := 0.55
const MAX_SPAWN_INTERVAL := 1.0
const FIRST_BOSS_TIME := 60.0
const DEFAULT_FIRST_BOSS_CAPTURES := 18
const BOSS_WARNING_DURATION := 2.0
const BOSS_COOLDOWN_DURATION := 90.0
const FISH_PATHS := [
	"res://resources/data/fish/clownfish.tres",
	"res://resources/data/fish/blue_tang.tres",
	"res://resources/data/fish/pufferfish.tres",
	"res://resources/data/fish/seahorse.tres",
	"res://resources/data/fish/sea_turtle.tres",
	"res://resources/data/fish/manta_ray.tres",
	"res://resources/data/fish/shark.tres",
	"res://resources/data/fish/golden_arowana.tres",
]
const BOSS_PATH := "res://resources/data/fish/whale_shark_boss.tres"

@export var fish_scene: PackedScene = preload("res://scenes/game/fish_actor.tscn")
@export var paths_parent_path := NodePath("../Paths")
@export var fish_parent_path := NodePath("../Fish")

var random := RandomNumberGenerator.new()
var ordinary_definitions: Array[FishDefinition] = []
var boss_definition: FishDefinition
var active_fish: Array[FishActor] = []
var elapsed_time := 0.0
var total_captures := 0
var boss_state := BossState.READY
var boss_warning_remaining := 0.0
var boss_cooldown_remaining := 0.0
var first_boss_captures := DEFAULT_FIRST_BOSS_CAPTURES
var _spawn_remaining := 0.0
var _next_serial := 1
var _paths: Array[Path2D] = []
var _fish_parent: Node
var _schedule_started := false


func _ready() -> void:
	if random.seed == 0:
		random.randomize()
	for path in FISH_PATHS:
		var definition := load(path) as FishDefinition
		assert(definition != null, "无法加载普通鱼资源：%s" % path)
		ordinary_definitions.append(definition)
	boss_definition = load(BOSS_PATH) as FishDefinition
	assert(boss_definition != null, "无法加载 Boss 资源")
	var paths_parent := get_node_or_null(paths_parent_path)
	if paths_parent != null:
		for child in paths_parent.get_children():
			if child is Path2D:
				_paths.append(child)
	_fish_parent = get_node_or_null(fish_parent_path)
	_spawn_remaining = random.randf_range(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)


func _process(delta: float) -> void:
	_schedule_started = true
	advance_schedule(delta)
	_spawn_remaining -= delta
	if _spawn_remaining <= 0.0:
		if get_ordinary_count() < MAX_ORDINARY_FISH:
			spawn_ordinary_fish()
		_spawn_remaining = random.randf_range(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)


func advance_schedule(delta: float) -> void:
	elapsed_time += delta
	match boss_state:
		BossState.READY:
			if elapsed_time >= FIRST_BOSS_TIME or total_captures >= first_boss_captures:
				boss_state = BossState.WARNING
				boss_warning_remaining = BOSS_WARNING_DURATION
				boss_warning_started.emit()
		BossState.WARNING:
			boss_warning_remaining = maxf(boss_warning_remaining - delta, 0.0)
			if is_zero_approx(boss_warning_remaining):
				_spawn_boss()
		BossState.COOLDOWN:
			boss_cooldown_remaining = maxf(boss_cooldown_remaining - delta, 0.0)
			if is_zero_approx(boss_cooldown_remaining):
				boss_state = BossState.READY


func set_total_captures(value: int) -> void:
	total_captures = maxi(value, 0)


func configure(new_first_boss_captures: int) -> bool:
	if new_first_boss_captures <= 0 or _schedule_started:
		push_error("Boss 首次捕获阈值必须在调度开始前配置为正整数")
		return false
	first_boss_captures = new_first_boss_captures
	return true


func reset_session() -> void:
	for fish in active_fish.duplicate():
		if is_instance_valid(fish):
			fish.queue_free()
	active_fish.clear()
	elapsed_time = 0.0
	total_captures = 0
	boss_state = BossState.READY
	boss_warning_remaining = 0.0
	boss_cooldown_remaining = 0.0
	_next_serial = 1
	_spawn_remaining = random.randf_range(MIN_SPAWN_INTERVAL, MAX_SPAWN_INTERVAL)


func get_ordinary_count() -> int:
	var count := 0
	for fish in active_fish:
		if is_instance_valid(fish) and fish.definition != null and not fish.definition.is_boss:
			count += 1
	return count


func choose_weighted_fish() -> FishDefinition:
	var total_weight := 0.0
	for definition in ordinary_definitions:
		total_weight += definition.spawn_weight
	if total_weight <= 0.0:
		return null
	var roll := random.randf_range(0.0, total_weight)
	var cursor := 0.0
	for definition in ordinary_definitions:
		cursor += definition.spawn_weight
		if roll <= cursor:
			return definition
	return ordinary_definitions.back()


func spawn_ordinary_fish() -> FishActor:
	if get_ordinary_count() >= MAX_ORDINARY_FISH:
		return null
	return _spawn_fish(choose_weighted_fish())


func _spawn_boss() -> void:
	if boss_state == BossState.ACTIVE or _has_active_boss():
		return
	var actor := _spawn_fish(boss_definition)
	if actor == null:
		boss_state = BossState.READY
		return
	boss_state = BossState.ACTIVE
	boss_spawned.emit()


func _spawn_fish(definition: FishDefinition) -> FishActor:
	if definition == null or fish_scene == null or _fish_parent == null or _paths.is_empty():
		return null
	var actor := fish_scene.instantiate() as FishActor
	if actor == null:
		return null
	var path := _paths[random.randi_range(0, _paths.size() - 1)]
	var reverse := random.randi_range(0, 1) == 1
	var travel_speed := random.randf_range(definition.speed_min, definition.speed_max)
	_fish_parent.add_child(actor)
	actor.configure(definition, path.curve, reverse, _next_serial, travel_speed)
	_next_serial += 1
	actor.removed.connect(_on_fish_removed)
	active_fish.append(actor)
	return actor


func _on_fish_removed(actor: FishActor, _was_captured: bool) -> void:
	active_fish.erase(actor)
	if actor.definition != null and actor.definition.is_boss:
		boss_state = BossState.COOLDOWN
		boss_cooldown_remaining = BOSS_COOLDOWN_DURATION


func _has_active_boss() -> bool:
	for fish in active_fish:
		if is_instance_valid(fish) and fish.definition != null and fish.definition.is_boss:
			return true
	return false
