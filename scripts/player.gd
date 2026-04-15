extends CharacterBody2D

const SPEED = 150.0

var Bullet = load("res://scenes/bullet.tscn")
var facing_horizontal = 1
var facing_vertical = 1

@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Muzzle


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()


func get_input():
	var input_direction = Input.get_vector("Left", "Right", "Up", "Down")
	velocity = input_direction * SPEED

	if input_direction.x != 0:
		facing_horizontal = sign(input_direction.x)
		sprite.flip_h = facing_horizontal < 0

	var anim = "idle"

	if input_direction.length() > 0:
		if abs(input_direction.x) > abs(input_direction.y):
			$Muzzle.position.x = abs($Muzzle.position.x) * sign(input_direction.x)
			anim = "walk_horizontal"
		elif input_direction.y < 0:
			facing_horizontal = 0
			facing_vertical = 1
			$Muzzle.position.x = 0
			$Muzzle.position.y = abs($Muzzle.position.y) * sign(input_direction.y)
			anim = "walk_up"
		else:
			facing_horizontal = 0
			facing_vertical = -1
			$Muzzle.position.x = 0
			$Muzzle.position.y = abs($Muzzle.position.y) * sign(input_direction.y)
			anim = "walk_down"
			

	if sprite.animation != anim:
		sprite.play(anim)

	if Input.is_action_just_pressed("Shoot"):
		shoot()


func shoot():
	var b = Bullet.instantiate()
	get_tree().current_scene.add_child(b)

	b.global_position = muzzle.global_position

	if facing_horizontal == -1:
		b.rotation = PI
	elif facing_horizontal == 1:
		b.rotation = 0
	elif facing_vertical == -1:
		b.rotation = PI / 2.0
	else:
		b.rotation = 3.0 * PI / 2.0
	
