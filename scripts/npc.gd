extends CharacterBody2D

const BUBBLE_WIDTH := 96.0
const BUBBLE_PADDING := 4.0
const BUBBLE_GAP := 12.0
const FONT_SIZE := 6
const DIALOG_LINES := [
	"You're awake. Good — we don't have much time.",
	"The ship's core AI went rogue an hour ago. It sealed the decks and turned security against us.",
	"Most of the crew is gone. The Cyclops is holding the navigation core in the lower hull.",
	"You're the last one who can reach it. Shut the AI down and save this ship.",
	"Test your weapon here first and get used to moving through the corridors.",
	"Grab the key on the platform, then press F at the door to reach the main decks.",
	"Good luck. The whole ship is counting on you.",
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
	_speech_label.modulate = Color.WHITE
	_speech_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_speech_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_speech_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_speech_label.add_theme_constant_override("outline_size", 1)
	_speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_speech_label.clip_text = true
	_speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	_layout_speech("%s\n[F] Next" % DIALOG_LINES[_dialog_index])


func _layout_speech(text: String) -> void:
	_speech_label.text = text
	_speech_label.custom_minimum_size = Vector2(BUBBLE_WIDTH, 0)

	await get_tree().process_frame

	var content_height: float = _speech_label.get_content_height()
	var bubble_height: float = content_height + BUBBLE_PADDING * 2.0
	var half_width: float = BUBBLE_WIDTH * 0.5 + BUBBLE_PADDING

	_speech_bubble.offset_left = -half_width
	_speech_bubble.offset_right = half_width
	_speech_bubble.offset_top = -(bubble_height + BUBBLE_GAP)
	_speech_bubble.offset_bottom = -BUBBLE_GAP

	_speech_label.offset_left = -half_width + BUBBLE_PADDING
	_speech_label.offset_right = half_width - BUBBLE_PADDING
	_speech_label.offset_top = -(bubble_height + BUBBLE_GAP) + BUBBLE_PADDING
	_speech_label.offset_bottom = -BUBBLE_GAP - BUBBLE_PADDING

	_speech_bubble.show()
	_speech_label.show()


func _style_speech_bubble() -> void:
	_speech_bubble.clip_contents = true
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
