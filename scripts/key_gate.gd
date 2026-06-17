extends StaticBody2D

const LABEL_MODULATE := Color(12.38, 12.38, 12.38, 1.0)

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _prompt_label: Label = $PromptLabel
@onready var _lock_sprite: AnimatedSprite2D = $LockSprite
@onready var _interact_area: Area2D = $InteractArea

var _player_in_range := false
var _nearby_player: Node2D = null
var _opened := false


func _ready() -> void:
	_style_prompt()
	_prompt_label.hide()
	if SaveManager.is_east_gate_open():
		queue_free()
		return
	_interact_area.body_entered.connect(_on_body_entered)
	_interact_area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if _opened or not _player_in_range:
		return

	_update_prompt()
	if _player_has_key() and Input.is_action_just_pressed("Interact"):
		_open()


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
	if _nearby_player == null:
		return false

	var key_count: Variant = _nearby_player.get("keys")
	return typeof(key_count) in [TYPE_INT, TYPE_FLOAT] and key_count > 0


func _update_prompt() -> void:
	if _player_has_key():
		_prompt_label.text = "unlock [F]"
		_prompt_label.show()
	else:
		_prompt_label.text = "locked — need key"
		_prompt_label.show()


func _open() -> void:
	if _opened:
		return

	_opened = true
	SaveManager.mark_east_gate_open()
	GameAudio.play_sfx("door")
	_prompt_label.hide()
	_lock_sprite.hide()
	_shape.set_deferred("disabled", true)
	set_deferred("collision_layer", 0)
	queue_free()


func _style_prompt() -> void:
	_prompt_label.modulate = LABEL_MODULATE
	_prompt_label.add_theme_color_override("font_color", Color.WHITE)
	_prompt_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_prompt_label.add_theme_constant_override("outline_size", 2)
