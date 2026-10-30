class_name FishActor
extends Area2D

signal capture_claimed(actor: FishActor, player_id: int)
signal removed(actor: FishActor, was_captured: bool)

enum Lifecycle { CAPTURABLE, CLAIMED, REMOVED }

var definition: FishDefinition
var instance_serial := 0
var lifecycle := Lifecycle.CAPTURABLE
var claimed_by_player := 0
var speed := 100.0
var _path_curve: Curve2D
var _path_progress := 0.0
var _path_length := 0.0
var _reverse_path := false


func configure(fish_definition: FishDefinition, path_curve: Curve2D, reverse_path: bool, serial: int, travel_speed: float) -> void:
	definition = fish_definition
	_path_curve = path_curve
	_reverse_path = reverse_path
	instance_serial = serial
	speed = travel_speed
	_path_length = _path_curve.get_baked_length()
	$AnimatedSprite2D.sprite_frames = definition.sprite_frames
	$AnimatedSprite2D.animation = &"swim"
	$AnimatedSprite2D.scale = Vector2.ONE * definition.display_scale
	$AnimatedSprite2D.flip_h = reverse_path
	$AnimatedSprite2D.play()
	var circle := $CollisionShape2D.shape as CircleShape2D
	circle.radius = definition.collision_radius
	add_to_group("boss" if definition.is_boss else "ordinary_fish")
	_update_path_position()
	queue_redraw()


func _physics_process(delta: float) -> void:
	if lifecycle != Lifecycle.CAPTURABLE or _path_curve == null:
		return
	_path_progress += speed * delta
	if _path_progress >= _path_length:
		remove_from_play(false)
		return
	_update_path_position()


func is_capturable() -> bool:
	return lifecycle == Lifecycle.CAPTURABLE


func try_claim_capture(player_id: int) -> bool:
	if lifecycle != Lifecycle.CAPTURABLE:
		return false
	lifecycle = Lifecycle.CLAIMED
	claimed_by_player = player_id
	capture_claimed.emit(self, player_id)
	return true


func remove_from_play(was_captured: bool) -> void:
	if lifecycle == Lifecycle.REMOVED:
		return
	lifecycle = Lifecycle.REMOVED
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)
	removed.emit(self, was_captured)
	queue_free()


func _update_path_position() -> void:
	var sample_distance := _path_length - _path_progress if _reverse_path else _path_progress
	var current_point := _path_curve.sample_baked(sample_distance, true)
	position = current_point


func _draw() -> void:
	if definition == null:
		return
	if definition.sprite_frames != null and definition.sprite_frames.get_frame_count(&"swim") > 0:
		return
	var radius := definition.collision_radius
	var body_color := Color("f3c34f") if not definition.is_boss else Color("55b9d6")
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_polyline(PackedVector2Array([
		Vector2(-radius * 0.75, -radius * 0.55),
		Vector2(-radius * 1.45, 0.0),
		Vector2(-radius * 0.75, radius * 0.55),
	]), Color("263752"), radius * 0.22)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("263752"), maxf(3.0, radius * 0.12))
	draw_circle(Vector2(radius * 0.35, -radius * 0.25), maxf(3.0, radius * 0.1), Color.WHITE)
	draw_circle(Vector2(radius * 0.38, -radius * 0.25), maxf(1.5, radius * 0.05), Color("263752"))
