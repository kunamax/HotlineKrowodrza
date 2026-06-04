extends Control

const GAME_SCENE := "res://scenes/game.tscn"

@onready var start_button: Button = $VBoxContainer/Button
@onready var quit_button: Button = $VBoxContainer/Button3


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()
