extends Node2D

const STAGGER_DELAY := 1.8
const ACTIVATE_DISTANCE_SCALE := 0.75
const SPAWN_DELAY_SCALE := 3.5

const SPIDER_SCENE := "res://scenes/enemy_spider.tscn"
const CYCLOPS_SCENE := "res://scenes/enemy_cyclops.tscn"
const SPIDER_SCALE := Vector2(0.54, 0.54)
const CYCLOPS_SCALE := Vector2(1.35, 1.35)

# id, position, scene, activate_distance, spawn_delay, scale
const SPAWN_LAYOUT: Array = [
	["S01", Vector2(270, 168), SPIDER_SCENE, 138.0, 0.0, SPIDER_SCALE],
	["S02", Vector2(330, 205), SPIDER_SCENE, 132.0, 0.12, SPIDER_SCALE],
	["S03", Vector2(470, 175), SPIDER_SCENE, 140.0, 0.0, SPIDER_SCALE],
	["S04", Vector2(545, 195), SPIDER_SCENE, 145.0, 0.18, SPIDER_SCALE],
	["S05", Vector2(610, 250), SPIDER_SCENE, 150.0, 0.0, SPIDER_SCALE],
	["S06", Vector2(235, 295), SPIDER_SCENE, 135.0, 0.0, SPIDER_SCALE],
	["S07", Vector2(305, 355), SPIDER_SCENE, 130.0, 0.1, SPIDER_SCALE],
	["S08", Vector2(360, 410), SPIDER_SCENE, 128.0, 0.22, SPIDER_SCALE],
	["S09", Vector2(195, 455), SPIDER_SCENE, 142.0, 0.0, SPIDER_SCALE],
	["S10", Vector2(255, 520), SPIDER_SCENE, 138.0, 0.15, SPIDER_SCALE],
	["S11", Vector2(450, 335), SPIDER_SCENE, 136.0, 0.0, SPIDER_SCALE],
	["S12", Vector2(520, 360), SPIDER_SCENE, 140.0, 0.2, SPIDER_SCALE],
	["S13", Vector2(585, 310), SPIDER_SCENE, 148.0, 0.0, SPIDER_SCALE],
	["S14", Vector2(635, 385), SPIDER_SCENE, 152.0, 0.16, SPIDER_SCALE],
	["S15", Vector2(600, 495), SPIDER_SCENE, 145.0, 0.0, SPIDER_SCALE],
	["S16", Vector2(655, 535), SPIDER_SCENE, 150.0, 0.25, SPIDER_SCALE],
	["S17", Vector2(175, 360), SPIDER_SCENE, 130.0, 0.0, SPIDER_SCALE],
	["S18", Vector2(215, 600), SPIDER_SCENE, 140.0, 0.1, SPIDER_SCALE],
	["S19", Vector2(340, 615), SPIDER_SCENE, 135.0, 0.0, SPIDER_SCALE],
	["S20", Vector2(430, 640), SPIDER_SCENE, 138.0, 0.18, SPIDER_SCALE],
	["S21", Vector2(520, 590), SPIDER_SCENE, 142.0, 0.0, SPIDER_SCALE],
	["S22", Vector2(580, 630), SPIDER_SCENE, 148.0, 0.2, SPIDER_SCALE],
	["S23", Vector2(395, 285), SPIDER_SCENE, 128.0, 0.0, SPIDER_SCALE],
	["S24", Vector2(480, 455), SPIDER_SCENE, 136.0, 0.14, SPIDER_SCALE],
	["C01", Vector2(495, 268), CYCLOPS_SCENE, 165.0, 0.0, CYCLOPS_SCALE],
	["C02", Vector2(355, 505), CYCLOPS_SCENE, 160.0, 0.35, CYCLOPS_SCALE],
	["C03", Vector2(575, 430), CYCLOPS_SCENE, 162.0, 0.5, CYCLOPS_SCALE],
]

var _spawn_queue: Array = []
var _armed_ids: Dictionary = {}
var _player: Node2D = null
var _game_root: Node2D = null


func _ready() -> void:
	_build_spawn_points()
	call_deferred("_align_spawn_points_to_floor")


func _get_pathfinding() -> Node:
	return get_parent().get_node_or_null("Pathfinding")


func _align_spawn_points_to_floor() -> void:
	var pathfinding := _get_pathfinding()
	if pathfinding == null:
		return

	for child in get_children():
		if not child.has_method("get_spawn_id"):
			continue

		var snapped: Vector2 = pathfinding.snap_to_ship_floor(child.global_position)
		if pathfinding.is_on_ship_floor(snapped):
			child.global_position = snapped
		elif child.has_method("set_enabled"):
			child.set_enabled(false)


func _build_spawn_points() -> void:
	if get_child_count() > 0:
		return

	var point_script: Script = load("res://scripts/enemy_spawn_point.gd")
	for entry: Array in SPAWN_LAYOUT:
		var point := Node2D.new()
		point.name = String(entry[0])
		point.set_script(point_script)
		point.position = entry[1]
		point.enemy_scene_path = entry[2]
		point.activate_distance = float(entry[3]) * ACTIVATE_DISTANCE_SCALE
		point.spawn_delay = float(entry[4]) * SPAWN_DELAY_SCALE
		point.enemy_scale = entry[5]
		add_child(point)


func _process(delta: float) -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_game_root = get_tree().current_scene as Node2D
	if _player == null or _game_root == null:
		return

	_queue_nearby_points()
	_advance_queue(delta)


func _queue_nearby_points() -> void:
	var tail_delay := float(_spawn_queue.size()) * STAGGER_DELAY
	for child in get_children():
		if not child.has_method("is_ready_to_trigger"):
			continue
		if child.has_method("is_enabled") and not child.is_enabled():
			continue
		if not child.is_ready_to_trigger(_player.global_position):
			continue
		var spawn_id: String = child.get_spawn_id()
		if _armed_ids.has(spawn_id):
			continue

		_armed_ids[spawn_id] = true
		var wait_time: float = tail_delay + float(child.spawn_delay)
		_spawn_queue.append({"point": child, "timer": wait_time})
		tail_delay += STAGGER_DELAY


func _advance_queue(delta: float) -> void:
	if _spawn_queue.is_empty():
		return

	_spawn_queue[0]["timer"] = _spawn_queue[0]["timer"] - delta
	while not _spawn_queue.is_empty() and _spawn_queue[0]["timer"] <= 0.0:
		var item: Dictionary = _spawn_queue.pop_front()
		var point: Node = item["point"]
		if point.has_method("spawn_enemy"):
			point.spawn_enemy(_game_root)


func capture_state() -> Array:
	var states: Array = []
	for child in get_children():
		if child.has_method("capture_state"):
			states.append(child.capture_state())
	return states


func restore_state(spawn_data: Array) -> void:
	var by_id: Dictionary = {}
	for entry: Dictionary in spawn_data:
		by_id[entry.get("id", "")] = entry

	for child in get_children():
		if not child.has_method("restore_state"):
			continue
		var spawn_id: String = child.get_spawn_id()
		if by_id.has(spawn_id):
			child.restore_state(by_id[spawn_id])
			if by_id[spawn_id].get("state", "pending") != "pending":
				_armed_ids[spawn_id] = true
