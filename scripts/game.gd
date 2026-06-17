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
	if not SaveManager.is_boss_door_used():
		return

	var boss_door := get_node_or_null("DoorToBossRoom")
	if boss_door != null:
		boss_door.queue_free()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
