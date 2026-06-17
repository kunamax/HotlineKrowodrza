extends CharacterBody2D

const LABEL_MODULATE := Color(12.38, 12.38, 12.38, 1.0)
const DIALOG_LINES := [
	"Hey, good to see you.",
	"Krowodrza took this district and their people are everywhere.",
	"Test your weapon first and get used to moving.",
	"The next room gets hot, so keep your distance.",
	"Once you pick up the key, open the door with F.",
	"Good luck. See you on the other side.",
]

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _proximity_area: Area2D = $ProximityArea
@onready var _speech_bubble: Panel = $SpeechBubble
@onready var _speech_label: Label = $SpeechLabel

var _player_in_range := false
var _dialog_index := 0
var _dialog_active := false


func _ready() -> void:
	_sprite.play("waving")
	_style_speech_bubble()
	_speech_bubble.hide()
	_speech_label.modulate = LABEL_MODULATE
	_speech_label.add_theme_color_override("font_color", Color.WHITE)
	_speech_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_speech_label.add_theme_constant_override("outline_size", 2)
	_speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_label.hide()
	_proximity_area.body_entered.connect(_on_body_entered)
	_proximity_area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	if Input.is_action_just_pressed("Interact"):
		_advance_dialog()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = true
	_sprite.play("idle")
	_start_dialog()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = false
	_dialog_active = false
	_dialog_index = 0
	_speech_bubble.hide()
	_speech_label.hide()
	_sprite.play("waving")


func _start_dialog() -> void:
	_dialog_active = true
	_dialog_index = 0
	_show_current_line()


func _advance_dialog() -> void:
	if not _dialog_active:
		_start_dialog()
		return

	_dialog_index += 1
	if _dialog_index >= DIALOG_LINES.size():
		_dialog_active = false
		_speech_bubble.hide()
		_speech_label.hide()
		return

	_show_current_line()


func _show_current_line() -> void:
	_speech_bubble.show()
	_speech_label.text = "%s\n[F] Next" % DIALOG_LINES[_dialog_index]
	_speech_label.show()


func _style_speech_bubble() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.92)
	style.border_color = Color.WHITE
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	_speech_bubble.add_theme_stylebox_override("panel", style)
