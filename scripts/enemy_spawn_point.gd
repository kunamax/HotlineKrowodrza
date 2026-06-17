extends Node2D

enum State { PENDING, ACTIVE, DEFEATED }

@export_file("*.tscn") var enemy_scene_path := "res://scenes/enemy_spider.tscn"
@export var activate_distance := 150.0
@export var spawn_delay := 0.0
@export var enemy_scale := Vector2(0.54, 0.54)

var state := State.PENDING
var enabled := true
var _enemy: CharacterBody2D = null


func set_enabled(value: bool) -> void:
	enabled = value


func is_enabled() -> bool:
	return enabled


func is_ready_to_trigger(player_pos: Vector2) -> bool:
	return enabled and state == State.PENDING and global_position.distance_to(player_pos) <= activate_distance


func get_spawn_id() -> String:
	return name


func capture_state() -> Dictionary:
	var entry := {
		"id": name,
		"state": _state_name(),
	}
	if state != State.ACTIVE or _enemy == null or not is_instance_valid(_enemy):
		return entry

	entry["health"] = _enemy.HEALTH
	entry["x"] = _enemy.global_position.x
	entry["y"] = _enemy.global_position.y
	return entry


func restore_state(data: Dictionary) -> void:
	var saved_state: String = data.get("state", "pending")
	match saved_state:
		"defeated":
			state = State.DEFEATED
		"active":
			state = State.PENDING
			_spawn_into_game(_get_game_root(), false)
			if _enemy != null:
				_enemy.global_position = Vector2(
					data.get("x", global_position.x),
					data.get("y", global_position.y)
				)
				_enemy.HEALTH = int(data.get("health", _enemy.MAX_HEALTH))
				_enemy.hp_bar.value = _enemy.HEALTH
		_:
			state = State.PENDING


func spawn_enemy(game_root: Node2D) -> CharacterBody2D:
	return _spawn_into_game(game_root, true)


func _spawn_into_game(game_root: Node2D, with_effect: bool) -> CharacterBody2D:
	if state == State.DEFEATED:
		return null
	if state == State.ACTIVE and _enemy != null and is_instance_valid(_enemy):
		return _enemy
	if game_root == null:
		return null

	var scene: PackedScene = load(enemy_scene_path)
	if scene == null:
		return null

	var enemy := scene.instantiate() as CharacterBody2D
	enemy.name = "Enemy_%s" % name
	if not _prepare_spawn_position():
		return null

	enemy.global_position = global_position
	enemy.scale = enemy_scale
	game_root.add_child(enemy)

	_enemy = enemy
	state = State.ACTIVE
	enemy.tree_exited.connect(_on_enemy_removed)

	if with_effect:
		_play_spawn_effect(enemy)
	return enemy


func _play_spawn_effect(enemy: CharacterBody2D) -> void:
	var target_scale := enemy_scale
	enemy.modulate.a = 0.0
	enemy.scale = target_scale * 0.2
	enemy.set_physics_process(false)
	enemy.set_process(false)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(enemy, "modulate:a", 1.0, 0.28)
	tween.tween_property(enemy, "scale", target_scale, 0.35).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_callback(func() -> void:
		if is_instance_valid(enemy):
			enemy.set_physics_process(true)
			enemy.set_process(true)
	)


func _on_enemy_removed() -> void:
	if state == State.ACTIVE:
		state = State.DEFEATED
	_enemy = null


func _state_name() -> String:
	match state:
		State.ACTIVE:
			return "active"
		State.DEFEATED:
			return "defeated"
		_:
			return "pending"


func _get_game_root() -> Node2D:
	var game := get_tree().current_scene as Node2D
	return game


func _prepare_spawn_position() -> bool:
	var spawn_pos: Vector2 = global_position
	var pathfinding := _get_pathfinding()
	if pathfinding == null:
		return true

	spawn_pos = pathfinding.snap_to_ship_floor(spawn_pos)
	if not pathfinding.is_on_ship_floor(spawn_pos):
		return false

	global_position = spawn_pos
	return true


func _get_pathfinding() -> Node:
	var game := _get_game_root()
	if game == null:
		return null
	return game.get_node_or_null("Pathfinding")
