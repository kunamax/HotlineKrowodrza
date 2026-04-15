extends CharacterBody2D


const SPEED = 150.0
const JUMP_VELOCITY = -200.0
#@export var Bullet : PackedScene
var Bullet = load("res://scenes/bullet.tscn")
var facing = 1


func get_input():
	var input_direction = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_direction * SPEED
	
	if input_direction.x != 0:
		facing = sign(input_direction.x)
		$Muzzle.position.x = abs($Muzzle.position.x) * sign(input_direction.x)
		$AnimatedSprite2D.flip_h = facing < 0
	
	if Input.is_action_just_pressed("Shoot"):
		shoot()


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

func shoot():
	var b = Bullet.instantiate()
	get_tree().current_scene.add_child(b)

	var muzzle = $Muzzle
	b.global_position = muzzle.global_position

	if facing == -1:
		b.rotation = PI
	else:
		b.rotation = 0
	
	
