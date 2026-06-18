extends Control

const GAME_STARTING_ROOM_SCENE := "res://scenes/game_starting_room.tscn"
const STARTING_MENU_SCENE := "res://scenes/starting_menu.tscn"

@onready var main_panel: VBoxContainer = $VBoxContainer
@onready var options_panel: VBoxContainer = $GameOptionsPanel
@onready var new_game_button: Button = $VBoxContainer/Button
@onready var options_button: Button = $VBoxContainer/Button2
@onready var main_menu_button: Button = $VBoxContainer/Button3
@onready var title_label: Label = $Label


func _ready() -> void:
	visible = false
	options_panel.hide()
	add_to_group("death_screen")
	new_game_button.pressed.connect(_on_new_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	options_panel.back_pressed.connect(_on_back_pressed)


func show_menu() -> void:
	_show_main_panel()
	visible = true
	get_tree().paused = true


func _show_main_panel() -> void:
	main_panel.show()
	title_label.show()
	options_panel.hide()


func _show_options_panel() -> void:
	main_panel.hide()
	title_label.hide()
	options_panel.sync_from_settings()
	options_panel.show()


func _on_options_pressed() -> void:
	_show_options_panel()


func _on_back_pressed() -> void:
	_show_main_panel()


func _on_new_game_pressed() -> void:
	SaveManager.delete_save()
	SaveManager.clear_load_on_start()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_STARTING_ROOM_SCENE)


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(STARTING_MENU_SCENE)
