extends CharacterBody2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _proximity_area: Area2D = $ProximityArea
@onready var _speech_label: Label = $SpeechLabel

var _greeted := false


func _ready() -> void:
	_sprite.play("waving")
	_speech_label.hide()
	_proximity_area.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _greeted or not body.is_in_group("player"):
		return
	_greeted = true
	_sprite.play("idle")
	_speech_label.show()
