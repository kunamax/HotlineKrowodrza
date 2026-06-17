extends CanvasLayer

@onready var key_count_label: Label = $MarginContainer/HBoxContainer/KeyCount
@onready var shield_label: Label = $MarginContainer/HBoxContainer/ShieldLabel
@onready var shield_icon: TextureRect = $MarginContainer/HBoxContainer/ShieldIcon


func _ready() -> void:
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if player.has_signal("keys_changed"):
		player.keys_changed.connect(_on_keys_changed)

	if player.has_signal("shield_changed"):
		player.shield_changed.connect(_on_shield_changed)

	_on_keys_changed(player.keys)
	_on_shield_changed(player.shield_active)


func _on_keys_changed(count: int) -> void:
	key_count_label.text = "x %d" % count


func _on_shield_changed(active: bool) -> void:
	shield_label.visible = active
	shield_icon.visible = active
