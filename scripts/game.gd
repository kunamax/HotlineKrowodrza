extends Node2D

const AUTOSAVE_INTERVAL := 10.0

var _autosave_timer: Timer

@onready var _death_menu: Control = $DeathLayer/you_died_menu


func _ready() -> void:
	_setup_autosave()
	GameAudio.play_music("dungeon", 0.6)

	if SaveManager.load_on_scene_start:
		SaveManager.load_into_game(self)
		SaveManager.clear_load_on_start()
	else:
		save_game()

	_apply_save_flags()
	call_deferred("_align_dungeon_key")
	call_deferred("_align_pickups_to_floor")
	if SaveManager.consume_fresh_scene_entry():
		call_deferred("_show_hud_tutorial")


func _align_dungeon_key() -> void:
	var key_node := get_node_or_null(SaveManager.KEY_NODE_NAME)
	if key_node == null:
		return

	var pathfinding := get_node_or_null("Pathfinding")
	if pathfinding == null:
		return

	var snapped_pos: Vector2 = pathfinding.snap_to_ship_floor(key_node.global_position)
	if pathfinding.is_on_ship_floor(snapped_pos):
		key_node.global_position = snapped_pos
	else:
		key_node.queue_free()


func _show_hud_tutorial() -> void:
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_method("show_tutorial"):
		hud.show_tutorial()


func _align_pickups_to_floor() -> void:
	var pathfinding := get_node_or_null("Pathfinding")
	if pathfinding == null:
		return

	for child in get_children():
		if not SaveManager.is_pickup_node_name(child.name):
			continue
		var snapped_pos: Vector2 = pathfinding.snap_to_ship_floor(child.global_position)
		if pathfinding.is_on_ship_floor(snapped_pos):
			child.global_position = snapped_pos
		else:
			child.queue_free()


func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _on_autosave_timeout() -> void:
	save_game()


func save_game() -> void:
	SaveManager.save_from_game(self)


func show_death_menu() -> void:
	SaveManager.delete_save()
	if _autosave_timer != null:
		_autosave_timer.stop()
	_death_menu.show_menu()


func _apply_save_flags() -> void:
	if SaveManager.is_boss_door_used():
		var boss_door := get_node_or_null("DoorToBossRoom")
		if boss_door != null:
			boss_door.queue_free()

	if SaveManager.is_east_gate_open():
		var east_gate := get_node_or_null("KeyGate")
		if east_gate != null:
			east_gate.queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
