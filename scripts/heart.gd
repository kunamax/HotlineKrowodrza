extends Area2D

const HEAL_AMOUNT := 15


func _ready() -> void:
	collision_mask = 2
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if body.has_method("heal"):
		body.heal(HEAL_AMOUNT)

	GameAudio.play_sfx("pickup", 1.08)

	var game := get_tree().current_scene as Node2D
	if game != null and game.has_method("save_game"):
		game.save_game()

	queue_free()
