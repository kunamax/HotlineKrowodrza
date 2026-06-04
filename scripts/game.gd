extends Node2D

const AUTOSAVE_INTERVAL := 10.0

var _autosave_timer: Timer


func _ready() -> void:
	_setup_autosave()

	if SaveManager.load_on_scene_start:
		SaveManager.load_into_game(self)
		SaveManager.clear_load_on_start()
	else:
		save_game()


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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
