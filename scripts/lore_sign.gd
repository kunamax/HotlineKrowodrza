extends Area2D

const LABEL_MODULATE := Color(12.38, 12.38, 12.38, 1.0)

@export_multiline var lines: PackedStringArray = PackedStringArray([
	"KROWODRZA DISTRICT — BLOCK C",
	"They sealed the old service tunnels after the takeover.",
	"Some say there's still loot in the east wing.",
	"You'll need the ward key.",
])

@onready var _prompt_label: Label = $PromptLabel
@onready var _text_label: Label = $TextLabel
@onready var _panel: Panel = $Panel

var _player_in_range := false
var _line_index := 0


func _ready() -> void:
	_style_labels()
	_panel.hide()
	_text_label.hide()
	_prompt_label.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	if Input.is_action_just_pressed("Interact"):
		_advance()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = true
	_line_index = 0
	_prompt_label.show()


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	_player_in_range = false
	_line_index = 0
	_prompt_label.hide()
	_panel.hide()
	_text_label.hide()


func _advance() -> void:
	if lines.is_empty():
		return

	_panel.show()
	_text_label.text = "%s\n[F] Next" % lines[_line_index]
	_text_label.show()
	_line_index += 1
	if _line_index >= lines.size():
		_line_index = 0


func _style_labels() -> void:
	for label: Label in [_prompt_label, _text_label]:
		label.modulate = LABEL_MODULATE
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_constant_override("outline_size", 2)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.92)
	style.border_color = Color(0.85, 0.85, 0.85, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)
