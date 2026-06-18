extends Area2D


func get_objective_position() -> Vector2:
	return global_position


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("collect_key"):
		body.collect_key()

	GameAudio.play_sfx("pickup")

	var game := get_tree().current_scene as Node2D
	if game != null and game.has_method("save_game"):
		game.save_game()

	queue_free()
