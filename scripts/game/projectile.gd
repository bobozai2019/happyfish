class_name Projectile
extends Area2D

signal resolution_requested(projectile: Projectile, hit_position: Vector2, create_net: bool)

const WORLD_MARGIN := 160.0

var player_id := 1
var direction := Vector2.UP
var cannon_definition: CannonDefinition
var _resolved := false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func configure(owner_player_id: int, travel_direction: Vector2, cannon: CannonDefinition) -> void:
	player_id = owner_player_id
	direction = travel_direction.normalized()
	cannon_definition = cannon
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if _resolved or cannon_definition == null:
		return
	global_position += direction * cannon_definition.projectile_speed * delta
	var viewport_size := get_viewport_rect().size
	var bounds := Rect2(Vector2(-WORLD_MARGIN, -WORLD_MARGIN), viewport_size + Vector2.ONE * WORLD_MARGIN * 2.0)
	if not bounds.has_point(global_position):
		resolve_once(false)


func resolve_once(create_net: bool, hit_position := Vector2.INF) -> bool:
	if _resolved:
		return false
	_resolved = true
	var resolved_position := global_position if hit_position == Vector2.INF else hit_position
	resolution_requested.emit(self, resolved_position, create_net)
	queue_free()
	return true


func _on_area_entered(area: Area2D) -> void:
	if area is FishActor and area.is_capturable():
		resolve_once(true, global_position)
