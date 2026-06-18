extends Area2D

@export var warning_text := "!"
@export var one_shot := true

@onready var _warning_label: Label = $WarningLabel

var _triggered := false


func _ready() -> void:
	if _warning_label != null:
		_warning_label.hide()
	body_entered.connect(_on_body_entered)
	_prepare_enemies()


func _prepare_enemies() -> void:
	for child in get_children():
		if child is CharacterBody2D:
			child.visible = false
			child.set_process(false)
			child.set_physics_process(false)


func _on_body_entered(body: Node2D) -> void:
	if _triggered and one_shot:
		return
	if not body.is_in_group("player"):
		return

	_triggered = true
	if _warning_label != null:
		_warning_label.text = warning_text
		_warning_label.show()

	for child in get_children():
		if child is CharacterBody2D:
			child.visible = true
			child.set_process(true)
			child.set_physics_process(true)

	if one_shot:
		monitoring = false
