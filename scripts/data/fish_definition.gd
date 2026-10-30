class_name FishDefinition
extends Resource

@export var id: StringName
@export var display_name: String
@export var sprite_frames: SpriteFrames
@export_range(0.1, 512.0, 0.1) var collision_radius: float = 1.0
@export_range(1, 10000, 1) var reward: int = 1
@export_range(0.001, 1.0, 0.001) var base_capture_chance: float = 0.01
@export_range(0.0, 1000.0, 0.1) var spawn_weight: float = 1.0
@export_range(0.1, 2000.0, 0.1) var speed_min: float = 1.0
@export_range(0.1, 2000.0, 0.1) var speed_max: float = 1.0
@export_range(0.01, 10.0, 0.01) var display_scale: float = 1.0
@export var is_boss: bool = false


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("id 不能为空")
	if display_name.strip_edges().is_empty():
		errors.append("display_name 不能为空")
	if sprite_frames == null or not sprite_frames.has_animation(&"swim"):
		errors.append("sprite_frames 必须包含 swim 动画")
	if collision_radius <= 0.0:
		errors.append("collision_radius 必须大于 0")
	if reward <= 0:
		errors.append("reward 必须大于 0")
	if base_capture_chance <= 0.0 or base_capture_chance > 1.0:
		errors.append("base_capture_chance 必须在 (0, 1] 内")
	if is_boss and not is_zero_approx(spawn_weight):
		errors.append("Boss spawn_weight 必须为 0")
	if not is_boss and spawn_weight <= 0.0:
		errors.append("普通鱼 spawn_weight 必须大于 0")
	if speed_min <= 0.0:
		errors.append("speed_min 必须大于 0")
	if speed_max < speed_min:
		errors.append("speed_max 必须大于等于 speed_min")
	if display_scale <= 0.0:
		errors.append("display_scale 必须大于 0")
	return errors
