extends Control

const GAME_SCENE := "res://scenes/game.tscn"
const GAME_STARTING_ROOM_SCENE := "res://scenes/game_starting_room.tscn"

@onready var main_panel: VBoxContainer = $VBoxContainer
@onready var options_panel: VBoxContainer = $GameOptionsPanel
@onready var continue_button: Button = $VBoxContainer/Button
@onready var new_game_button: Button = $VBoxContainer/Button2
@onready var options_button: Button = $VBoxContainer/Button3
@onready var quit_button: Button = $VBoxContainer/Button4
@onready var title_label: Label = $Label


func _ready() -> void:
	GameAudio.play_music("menu", 0.4)
	options_panel.hide()
	continue_button.pressed.connect(_on_continue_pressed)
	new_game_button.pressed.connect(_on_new_game_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	options_panel.back_pressed.connect(_on_back_pressed)
	_update_continue_button()


func _update_continue_button() -> void:
	continue_button.disabled = not SaveManager.has_save()


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


func _on_continue_pressed() -> void:
	if not SaveManager.has_save():
		return
	SaveManager.mark_load_on_start()
	get_tree().change_scene_to_file(SaveManager.get_saved_scene_path())


func _on_new_game_pressed() -> void:
	SaveManager.delete_save()
	SaveManager.clear_load_on_start()
	get_tree().change_scene_to_file(GAME_STARTING_ROOM_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
