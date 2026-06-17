extends Area2D

const LABEL_MODULATE := Color(12.38, 12.38, 12.38, 1.0)

@export var prompt_text := "open"
@export_file("*.tscn") var target_scene := "res://scenes/game.tscn"
@export var target_spawn := Vector2.ZERO
@export var requires_key := true
@export var is_boss_entrance := false

@onready var _prompt_label: Label = $PromptLabel
@onready var _marker_sprite: Sprite2D = $MarkerSprite
@onready var _glow_light: PointLight2D = $GlowLight

var _player_in_range := false
var _nearby_player: Node2D = null
var _pulse_tween: Tween = null


func _ready() -> void:
	_style_prompt_label()
	_prompt_label.text = prompt_text
	_prompt_label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_setup_entrance_visual()


func _setup_entrance_visual() -> void:
	if not is_boss_entrance:
		if _marker_sprite != null:
			_marker_sprite.hide()
		if _glow_light != null:
			_glow_light.hide()
		return

	if _marker_sprite != null:
		_marker_sprite.show()
		_marker_sprite.modulate = Color(1.0, 0.55, 0.2, 1.0)
	if _glow_light != null:
		_glow_light.show()
		_glow_light.color = Color(1.0, 0.45, 0.15)
	_start_boss_pulse()


func _start_boss_pulse() -> void:
	if _marker_sprite == null:
		return
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(_marker_sprite, "scale", Vector2(0.13, 0.13), 0.75)
	_pulse_tween.tween_property(_marker_sprite, "scale", Vector2(0.1, 0.1), 0.75)


func _process(_delta: float) -> void:
	if not _player_in_range or not _can_open_door():
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
	if not requires_key:
		return true

	if _nearby_player == null:
		return false

	var key_count: Variant = _nearby_player.get("keys")
	return typeof(key_count) in [TYPE_INT, TYPE_FLOAT] and key_count > 0


func _can_open_door() -> bool:
	return not target_scene.is_empty() and _player_has_key()


func _update_prompt() -> void:
	if _can_open_door():
		_prompt_label.text = prompt_text
		_prompt_label.show()
	else:
		_prompt_label.hide()


func _style_prompt_label() -> void:
	_prompt_label.modulate = LABEL_MODULATE
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 2)


func _open_door() -> void:
	if not _can_open_door():
		return

	GameAudio.play_sfx("door")

	var game := get_tree().current_scene as Node2D
	if game != null:
		SaveManager.prepare_game_entry(game, target_spawn, target_scene)

	SaveManager.mark_load_on_start()
	SaveManager.mark_fresh_scene_entry()
	get_tree().change_scene_to_file(target_scene)


func get_objective_position() -> Vector2:
	return global_position
