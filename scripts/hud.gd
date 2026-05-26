extends CanvasLayer

@onready var key_count_label: Label = $MarginContainer/HBoxContainer/KeyCount


func _ready() -> void:
	await get_tree().process_frame
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if player.has_signal("keys_changed"):
		player.keys_changed.connect(_on_keys_changed)

	_on_keys_changed(player.keys)


func _on_keys_changed(count: int) -> void:
	key_count_label.text = "x %d" % count
