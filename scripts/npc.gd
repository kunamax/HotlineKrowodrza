extends CharacterBody2D

const LABEL_MODULATE := Color(12.38, 12.38, 12.38, 1.0)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _proximity_area: Area2D = $ProximityArea
@onready var _speech_label: Label = $SpeechLabel

var _greeted := false


func _ready() -> void:
	_sprite.play("waving")
	_speech_label.modulate = LABEL_MODULATE
	_speech_label.add_theme_color_override("font_color", Color.WHITE)
	_speech_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_speech_label.add_theme_constant_override("outline_size", 2)
	_speech_label.hide()
	_proximity_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _greeted or not body.is_in_group("player"):
		return
	_greeted = true
	_sprite.play("idle")
	_speech_label.show()
