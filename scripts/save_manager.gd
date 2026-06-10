extends Node

const SAVE_PATH := "user://savegame.json"

var load_on_scene_start := false

const ENEMY_NAME_PREFIX := "Enemy_"
const KEY_NODE_NAME := "Key"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func mark_load_on_start() -> void:
	load_on_scene_start = true


func clear_load_on_start() -> void:
	load_on_scene_start = false


func save_from_game(game: Node2D) -> bool:
	var data := _collect_from_game(game)
	return _write_save(data)


func prepare_game_entry(game: Node2D, spawn_position: Vector2 = Vector2.ZERO) -> bool:
	var player := game.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		return false

	var data := {
		"version": 1,
		"player": {
			"x": spawn_position.x,
			"y": spawn_position.y,
			"health": player.HEALTH,
			"keys": player.keys,
		},
		"enemies": [],
		"keys": [{"name": KEY_NODE_NAME, "collected": player.keys > 0}],
	}
	return _write_save(data)


func load_into_game(game: Node2D) -> bool:
	var data := _read_save()
	if data.is_empty():
		return false
	_apply_to_game(game, data)
	return true


func _collect_from_game(game: Node2D) -> Dictionary:
	var player := game.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		return {}

	var player_data := {
		"x": player.global_position.x,
		"y": player.global_position.y,
		"health": player.HEALTH,
		"keys": player.keys,
	}

	var enemies: Array = []
	for child in game.get_children():
		if not child.name.begins_with(ENEMY_NAME_PREFIX):
			continue
		if not is_instance_valid(child) or not child.is_inside_tree():
			enemies.append({"name": child.name, "alive": false})
			continue
		enemies.append({
			"name": child.name,
			"alive": true,
			"x": child.global_position.x,
			"y": child.global_position.y,
			"health": child.HEALTH,
		})

	var keys: Array = []
	var key_node := game.get_node_or_null(KEY_NODE_NAME)
	keys.append({"name": KEY_NODE_NAME, "collected": key_node == null})

	return {
		"version": 1,
		"player": player_data,
		"enemies": enemies,
		"keys": keys,
	}


func _apply_to_game(game: Node2D, data: Dictionary) -> void:
	var player := game.get_node_or_null("Player") as CharacterBody2D
	var player_data: Dictionary = data.get("player", {})
	if player != null and not player_data.is_empty():
		player.global_position = Vector2(player_data.get("x", 0.0), player_data.get("y", 0.0))
		player.HEALTH = int(player_data.get("health", player.MAX_HEALTH))
		player.keys = int(player_data.get("keys", 0))
		player.hp_bar.value = player.HEALTH
		player.keys_changed.emit(player.keys)

	for enemy_data in data.get("enemies", []):
		var enemy_name: String = enemy_data.get("name", "")
		if enemy_name.is_empty():
			continue
		var enemy := game.get_node_or_null(enemy_name)
		if not enemy_data.get("alive", true):
			if enemy != null:
				enemy.queue_free()
			continue
		if enemy == null:
			continue
		enemy.global_position = Vector2(enemy_data.get("x", 0.0), enemy_data.get("y", 0.0))
		enemy.HEALTH = int(enemy_data.get("health", enemy.MAX_HEALTH))
		enemy.hp_bar.value = enemy.HEALTH

	for key_data in data.get("keys", []):
		if not key_data.get("collected", false):
			continue
		var key := game.get_node_or_null(key_data.get("name", KEY_NODE_NAME))
		if key != null:
			key.queue_free()


func _write_save(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not write save to %s" % SAVE_PATH)
		return false

	file.store_string(JSON.stringify(data))
	return true


func _read_save() -> Dictionary:
	if not has_save():
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}

	return parsed
