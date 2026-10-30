class_name NetEffect
extends Area2D

signal candidates_found(candidates: Array[FishActor], cannon: CannonDefinition, world_position: Vector2)

const DISPLAY_DURATION := 0.18

var player_id := 1
var cannon_definition: CannonDefinition
var _elapsed := 0.0
var _queried := false
var _query_delay_frames := 1


func configure(owner_player_id: int, cannon: CannonDefinition) -> void:
	player_id = owner_player_id
	cannon_definition = cannon
	var circle := $CollisionShape2D.shape as CircleShape2D
	circle.radius = cannon.net_radius_px
	queue_redraw()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if _query_delay_frames > 0:
		_query_delay_frames -= 1
	elif not _queried and cannon_definition != null:
		_queried = true
		var candidates: Array[FishActor] = []
		for area in get_overlapping_areas():
			if area is FishActor and area.is_capturable():
				candidates.append(area)
		candidates.sort_custom(func(a: FishActor, b: FishActor) -> bool: return a.instance_serial < b.instance_serial)
		candidates_found.emit(candidates, cannon_definition, global_position)
	if _elapsed >= DISPLAY_DURATION:
		queue_free()


func _draw() -> void:
	if cannon_definition == null:
		return
	draw_circle(Vector2.ZERO, cannon_definition.net_radius_px, Color(0.2, 0.9, 1.0, 0.18))
	draw_arc(Vector2.ZERO, cannon_definition.net_radius_px, 0.0, TAU, 48, Color(0.85, 1.0, 1.0, 0.9), 4.0)
