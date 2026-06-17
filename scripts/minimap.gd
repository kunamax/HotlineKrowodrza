extends Control

const MAP_SIZE := Vector2(148, 116)
const FLOOR_COLOR := Color(0.28, 0.3, 0.38, 0.95)
const WALL_COLOR := Color(0.08, 0.08, 0.12, 1.0)
const PLAYER_COLOR := Color(0.35, 0.9, 1.0, 1.0)
const KEY_COLOR := Color(1.0, 0.82, 0.2, 1.0)
const BOSS_COLOR := Color(1.0, 0.45, 0.15, 1.0)
const MARKER_RADIUS := 3.0

var _map_bounds := Rect2()
var _floor_points: PackedVector2Array = PackedVector2Array()
var _ready_to_draw := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = MAP_SIZE
	await get_tree().process_frame
	_cache_map_data()
	_ready_to_draw = true
	queue_redraw()


func _process(_delta: float) -> void:
	if _ready_to_draw:
		queue_redraw()


func _cache_map_data() -> void:
	var game := get_tree().current_scene as Node2D
	if game == null:
		return

	var pathfinding := game.get_node_or_null("Pathfinding")
	if pathfinding == null or not pathfinding.has_method("build_minimap_data"):
		return

	var data: Dictionary = pathfinding.build_minimap_data(2)
	_map_bounds = data.get("bounds", Rect2())
	_floor_points = data.get("points", PackedVector2Array())


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), WALL_COLOR, true)

	if _map_bounds.size.x <= 1.0 or _map_bounds.size.y <= 1.0:
		return

	for point in _floor_points:
		var mini_pos := _world_to_minimap(point)
		draw_rect(Rect2(mini_pos - Vector2(0.8, 0.8), Vector2(1.6, 1.6)), FLOOR_COLOR, true)

	var game := get_tree().current_scene as Node2D
	if game == null:
		return

	var player := game.get_node_or_null("Player") as Node2D
	if player != null:
		_draw_marker(_world_to_minimap(player.global_position), PLAYER_COLOR, MARKER_RADIUS)

	if not _player_has_key(game):
		var key := game.get_node_or_null(SaveManager.KEY_NODE_NAME) as Node2D
		if key != null and is_instance_valid(key):
			_draw_marker(_world_to_minimap(key.global_position), KEY_COLOR, MARKER_RADIUS - 0.5)
	else:
		var boss_door := game.get_node_or_null("DoorToBossRoom") as Node2D
		if boss_door != null and is_instance_valid(boss_door) \
				and not SaveManager.is_boss_door_consumed():
			_draw_marker(_world_to_minimap(boss_door.global_position), BOSS_COLOR, MARKER_RADIUS)


func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var normalized := (world_pos - _map_bounds.position) / _map_bounds.size
	normalized.x = clampf(normalized.x, 0.0, 1.0)
	normalized.y = clampf(normalized.y, 0.0, 1.0)
	var inner := MAP_SIZE - Vector2(8.0, 8.0)
	return Vector2(4.0, 4.0) + Vector2(normalized.x * inner.x, normalized.y * inner.y)


func _draw_marker(pos: Vector2, color: Color, radius: float) -> void:
	draw_circle(pos, radius + 1.2, Color(0.0, 0.0, 0.0, 0.75))
	draw_circle(pos, radius, color)


func _player_has_key(game: Node2D) -> bool:
	var player := game.get_node_or_null("Player")
	if player == null:
		return false
	var key_count: Variant = player.get("keys")
	return typeof(key_count) in [TYPE_INT, TYPE_FLOAT] and key_count > 0
