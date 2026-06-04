extends Node

const REGION_PADDING := 18
const MAX_REGION_SIZE := 64
const TILE_SIZE := Vector2(255, 255)

var tile_map: TileMapLayer
var tile_map_overlay: TileMapLayer
var astar := AStarGrid2D.new()
var cell_size := Vector2.ONE
var blocked_cache: Dictionary = {}
var cached_region := Rect2i()
var grid_ready := false

func _ready() -> void:
	tile_map = get_parent().get_node("Layer1") as TileMapLayer
	tile_map_overlay = get_parent().get_node("Layer2") as TileMapLayer
	cell_size = TILE_SIZE * tile_map.scale
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.cell_size = cell_size


func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	var from_cell := _world_to_cell(from_world)
	var to_cell := _world_to_cell(to_world)

	_ensure_region(from_cell, to_cell)

	if astar.is_in_boundsv(from_cell) and astar.is_point_solid(from_cell):
		from_cell = _find_nearest_walkable(from_cell, to_cell)

	to_cell = _find_nearest_walkable(to_cell, from_cell)

	if not astar.is_in_boundsv(from_cell) or not astar.is_in_boundsv(to_cell):
		return PackedVector2Array()

	var id_path := astar.get_id_path(from_cell, to_cell)
	if id_path.is_empty():
		return PackedVector2Array()

	var path := PackedVector2Array()
	for i in range(id_path.size()):
		var point := _cell_to_world_center(id_path[i])
		if path.is_empty() or path[path.size() - 1].distance_to(point) > 4.0:
			path.append(point)
	return path


func _ensure_region(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var min_x := mini(from_cell.x, to_cell.x) - REGION_PADDING
	var min_y := mini(from_cell.y, to_cell.y) - REGION_PADDING
	var max_x := maxi(from_cell.x, to_cell.x) + REGION_PADDING
	var max_y := maxi(from_cell.y, to_cell.y) + REGION_PADDING
	var needed := Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)

	if grid_ready and _region_contains(cached_region, needed):
		return

	if grid_ready:
		var merged := _merge_regions(cached_region, needed)
		if merged.size.x <= MAX_REGION_SIZE and merged.size.y <= MAX_REGION_SIZE:
			needed = merged

	_build_region(needed)
	cached_region = needed
	grid_ready = true


func _build_region(region: Rect2i) -> void:
	astar.region = region
	astar.offset = tile_map.to_global(tile_map.map_to_local(region.position))
	astar.update()

	for x in range(region.position.x, region.end.x):
		for y in range(region.position.y, region.end.y):
			var cell := Vector2i(x, y)
			astar.set_point_solid(cell, _is_cell_blocked(cell))


func _is_cell_blocked(cell: Vector2i) -> bool:
	if blocked_cache.has(cell):
		return blocked_cache[cell]

	var blocked := _cell_has_wall(cell)
	if not blocked:
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			if _cell_has_wall(cell + offset):
				blocked = true
				break

	blocked_cache[cell] = blocked
	return blocked


func _cell_has_wall(cell: Vector2i) -> bool:
	if _tilemap_cell_has_collision(tile_map, cell):
		return true

	if tile_map_overlay == null:
		return false

	var world_center := _cell_to_world_center(cell)
	var overlay_cell := tile_map_overlay.local_to_map(tile_map_overlay.to_local(world_center))
	return _tilemap_cell_has_collision(tile_map_overlay, overlay_cell)


func _tilemap_cell_has_collision(tilemap: TileMapLayer, cell: Vector2i) -> bool:
	var data := tilemap.get_cell_tile_data(cell)
	if data == null:
		return false
	return data.get_collision_polygons_count(0) > 0


func _world_to_cell(world_pos: Vector2) -> Vector2i:
	return tile_map.local_to_map(tile_map.to_local(world_pos))


func _cell_to_world_center(cell: Vector2i) -> Vector2:
	var local := tile_map.map_to_local(cell) + cell_size * 0.5
	return tile_map.to_global(local)


func _find_nearest_walkable(cell: Vector2i, fallback: Vector2i) -> Vector2i:
	if astar.is_in_boundsv(cell) and not astar.is_point_solid(cell):
		return cell

	for radius in range(1, 10):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if abs(dx) != radius and abs(dy) != radius:
					continue
				var candidate := cell + Vector2i(dx, dy)
				if astar.is_in_boundsv(candidate) and not astar.is_point_solid(candidate):
					return candidate

	return fallback


func _region_contains(outer: Rect2i, inner: Rect2i) -> bool:
	return inner.position.x >= outer.position.x \
		and inner.position.y >= outer.position.y \
		and inner.end.x <= outer.end.x \
		and inner.end.y <= outer.end.y


func _merge_regions(a: Rect2i, b: Rect2i) -> Rect2i:
	var min_x := mini(a.position.x, b.position.x)
	var min_y := mini(a.position.y, b.position.y)
	var max_x := maxi(a.end.x, b.end.x)
	var max_y := maxi(a.end.y, b.end.y)
	return Rect2i(min_x, min_y, max_x - min_x, max_y - min_y)
