extends StaticBody2D

const LABEL_MODULATE := Color(12.38, 12.38, 12.38, 1.0)

@export var texture_with_key: Texture2D
@export var texture_no_key: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _proximity_area: Area2D = $ProximityArea
@onready var _prompt_label: Label = $PromptLabel

var _key_collected := false
var _player_in_range := false
var _nearby_player: Node2D = null


func _ready() -> void:
	_sprite.texture = texture_with_key
	_prompt_label.modulate = LABEL_MODULATE
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 2)
	_prompt_label.hide()
	_proximity_area.body_entered.connect(_on_body_entered)
	_proximity_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _key_collected or not _player_in_range:
		return

	if Input.is_action_just_pressed("Interact"):
		_pick_up_key()


func _on_body_entered(body: Node2D) -> void:
	if _key_collected or not body.is_in_group("player"):
		return

	_player_in_range = true
	_nearby_player = body
	_prompt_label.show()


func _on_body_exited(body: Node2D) -> void:
	if body != _nearby_player:
		return

	_player_in_range = false
	_nearby_player = null
	_prompt_label.hide()


func _pick_up_key() -> void:
	var player := _nearby_player
	_key_collected = true
	_player_in_range = false
	_nearby_player = null
	_prompt_label.hide()
	_sprite.texture = texture_no_key

	if player != null and player.has_method("collect_key"):
		player.collect_key()

	var game := get_tree().current_scene as Node2D
	if game != null and game.has_method("save_game"):
		game.save_game()
