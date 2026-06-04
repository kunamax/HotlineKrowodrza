extends Control

@onready var resume_button: Button = $VBoxContainer/Button
@onready var quit_button: Button = $VBoxContainer/Button3


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or event.is_echo():
		return
	toggle_pause()
	get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	if visible:
		close_pause()
	else:
		open_pause()


func open_pause() -> void:
	visible = true
	get_tree().paused = true


func close_pause() -> void:
	visible = false
	get_tree().paused = false


func _on_resume_pressed() -> void:
	close_pause()


func _on_quit_pressed() -> void:
	get_tree().quit()
