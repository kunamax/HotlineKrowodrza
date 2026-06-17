extends Node2D

const AUTOSAVE_INTERVAL := 10.0
const ENDING_SCENE := "res://scenes/ending_scene.tscn"

var _autosave_timer: Timer
var _ending_started := false

@onready var _death_menu: Control = $DeathLayer/you_died_menu
@onready var _boss: Node = $Boss


func _ready() -> void:
	_setup_autosave()

	if SaveManager.load_on_scene_start:
		SaveManager.load_into_game(self)
		SaveManager.clear_load_on_start()
	else:
		save_game()

	_watch_boss_state()


func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _on_autosave_timeout() -> void:
	if _ending_started:
		return
	save_game()


func save_game() -> void:
	SaveManager.save_from_game(self)


func show_death_menu() -> void:
	SaveManager.delete_save()
	if _autosave_timer != null:
		_autosave_timer.stop()
	_death_menu.show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _watch_boss_state() -> void:
	if _boss == null:
		_on_boss_defeated()
		return

	_boss.tree_exited.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	if _ending_started:
		return

	_ending_started = true
	SaveManager.delete_save()
	if _autosave_timer != null:
		_autosave_timer.stop()
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file(ENDING_SCENE)
