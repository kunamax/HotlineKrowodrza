extends Area2D

const GAME_SCENE := "res://scenes/game.tscn"
const GAME_SPAWN := Vector2.ZERO

@export var prompt_text := "open"

@onready var _prompt_label: Label = $PromptLabel

var _player_in_range := false
var _nearby_player: Node2D = null


func _ready() -> void:
	_prompt_label.text = prompt_text
	_prompt_label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_in_range or not _player_has_key():
		return

	if Input.is_action_just_pressed("Interact"):
		_open_door()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = true
	_nearby_player = body
	if body.has_signal("keys_changed") and not body.keys_changed.is_connected(_update_prompt):
		body.keys_changed.connect(_update_prompt)
	_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body != _nearby_player:
		return

	if body.has_signal("keys_changed") and body.keys_changed.is_connected(_update_prompt):
		body.keys_changed.disconnect(_update_prompt)

	_player_in_range = false
	_nearby_player = null
	_prompt_label.hide()


func _player_has_key() -> bool:
	return _nearby_player != null and _nearby_player.keys > 0


func _update_prompt() -> void:
	if _player_has_key():
		_prompt_label.text = prompt_text
		_prompt_label.show()
	else:
		_prompt_label.hide()


func _open_door() -> void:
	if not _player_has_key():
		return

	var game := get_tree().current_scene as Node2D
	if game != null:
		SaveManager.prepare_game_entry(game, GAME_SPAWN)

	SaveManager.mark_load_on_start()
	get_tree().change_scene_to_file(GAME_SCENE)
