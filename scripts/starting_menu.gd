extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const GAME_STARTING_ROOM_SCENE := "res://scenes/game_starting_room.tscn"

@onready var continue_button: Button = $VBoxContainer/Button
@onready var new_game_button: Button = $VBoxContainer/Button2
@onready var quit_button: Button = $VBoxContainer/Button4


func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	_update_continue_button()


func _update_continue_button() -> void:
	continue_button.disabled = not SaveManager.has_save()


func _on_continue_pressed() -> void:
	if not SaveManager.has_save():
		return
	SaveManager.mark_load_on_start()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_new_game_pressed() -> void:
	SaveManager.delete_save()
	SaveManager.clear_load_on_start()
	get_tree().change_scene_to_file(GAME_STARTING_ROOM_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
