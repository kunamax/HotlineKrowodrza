extends Area2D

var speed = 1500
var damage = 1

func _physics_process(delta):
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * speed * delta

#func _on_Bullet_body_entered(body):
	##if body.is_in_group("mobs"):
		##body.queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		var hit_dir: Vector2 = Vector2.RIGHT.rotated(rotation)
		body.take_damage(damage, hit_dir)
		queue_free()
