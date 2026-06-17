extends Area2D


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("grant_shield"):
		body.grant_shield()

	GameAudio.play_sfx("shield")

	var game := get_tree().current_scene as Node2D
	if game != null and game.has_method("save_game"):
		game.save_game()

	queue_free()
