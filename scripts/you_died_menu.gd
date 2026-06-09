extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const STARTING_MENU_SCENE := "res://scenes/starting_menu.tscn"

@onready var new_game_button: Button = $VBoxContainer/Button
@onready var main_menu_button: Button = $VBoxContainer/Button3


func _ready() -> void:
	visible = false
	add_to_group("death_screen")
	new_game_button.pressed.connect(_on_new_game_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)


func show_menu() -> void:
	visible = true
	get_tree().paused = true


func _on_new_game_pressed() -> void:
	SaveManager.delete_save()
	SaveManager.clear_load_on_start()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(STARTING_MENU_SCENE)
