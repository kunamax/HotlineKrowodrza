extends Control

const STARTING_MENU_SCENE := "res://scenes/starting_menu.tscn"

@onready var main_panel: VBoxContainer = $VBoxContainer
@onready var options_panel: VBoxContainer = $GameOptionsPanel
@onready var resume_button: Button = $VBoxContainer/Button
@onready var options_button: Button = $VBoxContainer/Button2
@onready var main_menu_button: Button = $VBoxContainer/Button3
@onready var title_label: Label = $Label


func _ready() -> void:
	visible = false
	options_panel.hide()
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	resume_button.pressed.connect(_on_resume_pressed)
	options_button.pressed.connect(_on_options_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)
	options_panel.back_pressed.connect(_on_back_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if _is_death_screen_visible():
		return
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	if options_panel.visible:
		_show_main_panel()
	else:
		toggle_pause()
	get_viewport().set_input_as_handled()


func _is_death_screen_visible() -> bool:
	var death_screen := get_tree().get_first_node_in_group("death_screen")
	return death_screen != null and death_screen.visible


func toggle_pause() -> void:
	if visible:
		close_pause()
	else:
		open_pause()


func open_pause() -> void:
	options_panel.sync_from_settings()
	_show_main_panel()
	visible = true
	get_tree().paused = true
	_save_game()


func close_pause() -> void:
	visible = false
	options_panel.hide()
	main_panel.show()
	get_tree().paused = false


func _show_main_panel() -> void:
	main_panel.show()
	title_label.show()
	options_panel.hide()


func _show_options_panel() -> void:
	main_panel.hide()
	title_label.hide()
	options_panel.sync_from_settings()
	options_panel.show()


func _on_resume_pressed() -> void:
	close_pause()


func _on_options_pressed() -> void:
	_show_options_panel()


func _on_back_pressed() -> void:
	_show_main_panel()


func _on_main_menu_pressed() -> void:
	_save_game()
	get_tree().paused = false
	get_tree().change_scene_to_file(STARTING_MENU_SCENE)


func _save_game() -> void:
	var game := get_tree().current_scene as Node2D
	if game == null:
		return
	if game.has_method("save_game"):
		game.save_game()
	else:
		SaveManager.save_from_game(game)
