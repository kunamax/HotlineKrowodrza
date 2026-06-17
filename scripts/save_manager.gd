extends Node

const SAVE_PATH := "user://savegame.json"
const DEFAULT_SCENE := "res://scenes/game.tscn"

var load_on_scene_start := false

const ENEMY_NAME_PREFIX := "Enemy_"
const KEY_NODE_NAME := "Key"
const HEART_NODE_NAME := "Heart"
const SHIELD_NODE_NAME := "Shield"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func mark_load_on_start() -> void:
	load_on_scene_start = true


func clear_load_on_start() -> void:
	load_on_scene_start = false


func get_saved_scene_path() -> String:
	var data := _read_save()
	var scene: String = data.get("scene", DEFAULT_SCENE)
	if scene.is_empty():
		return DEFAULT_SCENE
	return scene


func is_boss_door_used() -> bool:
	var flags: Dictionary = _read_save().get("flags", {})
	return flags.get("boss_door_used", false)


func save_from_game(game: Node2D) -> bool:
	var data := _collect_from_game(game)
	return _write_save(data)


func prepare_game_entry(
	game: Node2D,
	spawn_position: Vector2 = Vector2.ZERO,
	target_scene: String = ""
) -> bool:
	var player := game.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		return false

	var scene_path := target_scene if not target_scene.is_empty() else _scene_path_for(game)
	var flags: Dictionary = _read_save().get("flags", {}).duplicate()
	if scene_path.contains("boss_room"):
		flags["boss_door_used"] = true

	var data := {
		"version": 2,
		"scene": scene_path,
		"player": _player_data_from(player, spawn_position, true),
		"enemies": [],
		"keys": [{"name": KEY_NODE_NAME, "collected": player.keys > 0}],
		"pickups": _collect_pickups(game),
		"flags": flags,
	}
	return _write_save(data)


func load_into_game(game: Node2D) -> bool:
	var data := _read_save()
	if data.is_empty():
		return false
	_apply_to_game(game, data)
	return true


func _scene_path_for(game: Node2D) -> String:
	if game.scene_file_path.is_empty():
		return DEFAULT_SCENE
	return game.scene_file_path


func _player_data_from(
	player: CharacterBody2D,
	position: Vector2,
	use_spawn: bool
) -> Dictionary:
	return {
		"x": position.x if use_spawn else player.global_position.x,
		"y": position.y if use_spawn else player.global_position.y,
		"health": player.HEALTH,
		"keys": player.keys,
		"shield": player.shield_active,
	}


func _collect_from_game(game: Node2D) -> Dictionary:
	var player := game.get_node_or_null("Player") as CharacterBody2D
	if player == null:
		return {}

	var player_data := _player_data_from(player, Vector2.ZERO, false)

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
		"version": 2,
		"scene": _scene_path_for(game),
		"player": player_data,
		"enemies": enemies,
		"keys": keys,
		"pickups": _collect_pickups(game),
		"flags": _read_save().get("flags", {}),
	}


func _collect_pickups(game: Node2D) -> Array:
	var pickups: Array = []
	for node_name in [HEART_NODE_NAME, SHIELD_NODE_NAME]:
		var node := game.get_node_or_null(node_name)
		pickups.append({"name": node_name, "collected": node == null})
	return pickups


func _apply_to_game(game: Node2D, data: Dictionary) -> void:
	var player := game.get_node_or_null("Player") as CharacterBody2D
	var player_data: Dictionary = data.get("player", {})
	if player != null and not player_data.is_empty():
		player.global_position = Vector2(player_data.get("x", 0.0), player_data.get("y", 0.0))
		player.HEALTH = int(player_data.get("health", player.MAX_HEALTH))
		player.keys = int(player_data.get("keys", 0))
		player.hp_bar.value = player.HEALTH
		player.keys_changed.emit(player.keys)

		if player.has_method("set_shield_active"):
			player.set_shield_active(player_data.get("shield", false))

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

	for pickup_data in data.get("pickups", []):
		if not pickup_data.get("collected", false):
			continue
		var pickup := game.get_node_or_null(pickup_data.get("name", ""))
		if pickup != null:
			pickup.queue_free()


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
