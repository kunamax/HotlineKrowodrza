extends Area2D

var speed = 1500

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta

#func _on_Bullet_body_entered(body):
	##if body.is_in_group("mobs"):
		##body.queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		return
	print("HIT:", body.name)
	queue_free()
