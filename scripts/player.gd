extends CharacterBody2D

const SPEED = 85.0
const MUZZLE_OFFSET = 14.0

var MAX_HEALTH = 6
var HEALTH = 6
var keys := 0

signal keys_changed(key_count: int)

var Bullet = load("res://scenes/bullet.tscn")
var facing_horizontal = 1
var facing_vertical = 1

@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Muzzle
@onready var hp_bar = $HealthBar

func _ready():
	add_to_group("player")
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = HEALTH

func _physics_process(_delta: float) -> void:
	get_input()
	_update_aim()
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
			facing_horizontal = sign(input_direction.x)
			facing_vertical = 0
			anim = "walk_horizontal"
		elif input_direction.y < 0:
			facing_horizontal = 0
			facing_vertical = 1
			anim = "walk_up"
		else:
			facing_horizontal = 0
			facing_vertical = -1
			anim = "walk_down"

	if sprite.animation != anim:
		sprite.play(anim)

	if Input.is_action_just_pressed("Shoot"):
		shoot()


func _update_aim() -> void:
	var aim_direction: Vector2 = _get_aim_direction()
	muzzle.position = aim_direction * MUZZLE_OFFSET

	if abs(aim_direction.x) > 0.1:
		sprite.flip_h = aim_direction.x < 0


func _get_aim_direction() -> Vector2:
	var direction: Vector2 = get_global_mouse_position() - global_position
	if direction.length() < 1.0:
		if facing_horizontal != 0:
			return Vector2(facing_horizontal, 0)
		if facing_vertical == 1:
			return Vector2.UP
		return Vector2.DOWN
	return direction.normalized()


func shoot():
	var aim_direction: Vector2 = get_global_mouse_position() - muzzle.global_position
	if aim_direction.length() < 1.0:
		aim_direction = _get_aim_direction()
	else:
		aim_direction = aim_direction.normalized()

	var b = Bullet.instantiate()
	get_tree().current_scene.add_child(b)
	b.global_position = muzzle.global_position
	b.rotation = aim_direction.angle()


func take_damage(amount):
	HEALTH -= amount
	hp_bar.value = HEALTH
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if HEALTH <= 0:
		die()


func collect_key() -> void:
	keys += 1
	keys_changed.emit(keys)


func die():
	get_tree().reload_current_scene()
