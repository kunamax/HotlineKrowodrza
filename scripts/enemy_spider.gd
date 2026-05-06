extends CharacterBody2D

var MAX_HEALTH = 3
var HEALTH = 3

var speed = 120
var gravity = 800

var direction = 1
var player = null

var detect_range = 250
var lose_range = 350

var jump_strength = -350
var can_jump = true

@onready var hp_bar = $HealthBar

func _ready():
	player = get_tree().get_first_node_in_group("player")
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = HEALTH

func _physics_process(delta):

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0
		can_jump = true

	if player == null:
		patrol()
	else:
		chase_player()

	move_and_slide()

	if is_on_wall():
		direction *= -1
		try_jump()

func patrol():
	velocity.x = direction * speed

func chase_player():
	var distance = position.distance_to(player.position)

	if distance < detect_range:
		direction = sign(player.position.x - position.x)
		velocity.x = direction * speed * 1.4

		if player.position.y < position.y - 20 and can_jump:
			try_jump()

	elif distance > lose_range:
		player = null
		patrol()
	else:
		patrol()

func try_jump():
	if is_on_floor():
		velocity.y = jump_strength
		can_jump = false

func take_damage(amount):
	HEALTH -= amount
	hp_bar.value = HEALTH
	modulate = Color(1,0,0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1,1,1)

	if HEALTH <= 0:
		die()

func die():
	queue_free()
