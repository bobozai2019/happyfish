class_name CannonDefinition
extends Resource

const ALLOWED_MULTIPLIERS: Array[int] = [1, 2, 5]

@export var multiplier: int = 1
@export_range(1, 1000, 1) var shot_cost: int = 1
@export_range(0.01, 100.0, 0.01) var probability_multiplier: float = 1.0
@export_range(1.0, 1000.0, 1.0) var net_radius_px: float = 72.0
@export_range(0.1, 10.0, 0.01) var fire_interval_sec: float = 0.25
@export_range(1.0, 5000.0, 1.0) var projectile_speed: float = 900.0
@export var projectile_scene: PackedScene
@export var shot_audio: AudioStream


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if multiplier not in ALLOWED_MULTIPLIERS:
		errors.append("multiplier 只能是 1、2 或 5")
	if shot_cost <= 0:
		errors.append("shot_cost 必须大于 0")
	if probability_multiplier <= 0.0:
		errors.append("probability_multiplier 必须大于 0")
	if net_radius_px <= 0.0:
		errors.append("net_radius_px 必须大于 0")
	if fire_interval_sec < 0.1:
		errors.append("fire_interval_sec 必须大于等于 0.1")
	if projectile_speed <= 0.0:
		errors.append("projectile_speed 必须大于 0")
	if projectile_scene == null or not projectile_scene.can_instantiate():
		errors.append("projectile_scene 必须可实例化")
	if shot_audio == null:
		errors.append("shot_audio 必须可播放")
	return errors
