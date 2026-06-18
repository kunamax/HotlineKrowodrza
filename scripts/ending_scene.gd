extends Control

const STARTING_MENU_SCENE := "res://scenes/starting_menu.tscn"
const SCROLL_SPEED := 60.0
const RESTART_OFFSET_Y := 520.0

@onready var _credits_container: VBoxContainer = $CreditsContainer


func _ready() -> void:
	GameAudio.play_music("ending", 0.8)
	_credits_container.position.y = RESTART_OFFSET_Y


func _process(delta: float) -> void:
	_credits_container.position.y -= SCROLL_SPEED * delta

	if _credits_container.position.y < -320.0:
		_credits_container.position.y = RESTART_OFFSET_Y

	if Input.is_action_just_pressed("Interact") or Input.is_action_just_pressed("Shoot"):
		get_tree().change_scene_to_file(STARTING_MENU_SCENE)
