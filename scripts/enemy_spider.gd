extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

var MAX_HEALTH = 3
var HEALTH = 3

var speed = 120
var chase_speed = 100
var attack_lunge_speed = 120

var direction = 1
var player = null
var state = State.PATROL

var detect_range = 250
var lose_range = 350
var keep_distance = 40
var distance_margin = 10
var attack_range = 55

var attack_cooldown = 1.2
var attack_cooldown_timer = 0.0
var attack_windup = 0.25
var attack_lunge_time = 0.2
var attack_timer = 0.0
var attack_lunging = false
var attack_damage = 1
var hit_range = 35
var attack_hit = false

@onready var hp_bar = $HealthBar
@onready var sprite = $AnimatedSprite2D

func _ready():
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = HEALTH

func _physics_process(delta):
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	_update_player_reference()
	_update_state()

	match state:
		State.PATROL:
			_patrol()
		State.CHASE:
			_chase_player()
		State.ATTACK:
			_attack_player(delta)

	move_and_slide()

	if state == State.PATROL and get_slide_collision_count() > 0:
		direction *= -1

func _update_player_reference():
	var potential_player = get_tree().get_first_node_in_group("player")
	if potential_player == null:
		player = null
		return

	var distance = position.distance_to(potential_player.position)

	if player == null:
		if distance <= detect_range:
			player = potential_player
	elif distance > lose_range:
		player = null

func _update_state():
	if player == null:
		if state != State.ATTACK or attack_timer <= 0.0:
			state = State.PATROL
		return

	var distance = position.distance_to(player.position)

	if state == State.ATTACK:
		return

	if distance <= attack_range and attack_cooldown_timer <= 0.0:
		state = State.ATTACK
		attack_timer = attack_windup + attack_lunge_time
		attack_lunging = false
		attack_hit = false
		velocity = Vector2.ZERO
	elif distance <= detect_range:
		state = State.CHASE
	else:
		state = State.PATROL

func _patrol():
	velocity = Vector2(direction * speed, 0)
	sprite.flip_h = direction < 0

func _chase_player():
	if player == null:
		velocity = Vector2.ZERO
		return

	var to_player = player.position - position
	var distance = to_player.length()
	_face_player()

	if distance > keep_distance + distance_margin:
		velocity = to_player.normalized() * chase_speed
	elif distance < keep_distance - distance_margin:
		velocity = -to_player.normalized() * chase_speed * 0.5
	else:
		velocity = Vector2.ZERO

func _attack_player(delta):
	if player == null:
		state = State.PATROL
		velocity = Vector2.ZERO
		return

	_face_player()
	attack_timer -= delta

	if attack_timer > attack_lunge_time:
		velocity = Vector2.ZERO
	elif attack_timer > 0.0:
		var to_player = player.position - position
		var distance = to_player.length()

		if not attack_lunging:
			attack_lunging = true

		if distance > keep_distance - 5:
			velocity = to_player.normalized() * attack_lunge_speed
		else:
			velocity = Vector2.ZERO

		if distance <= hit_range:
			_deal_attack_damage()
	else:
		attack_cooldown_timer = attack_cooldown
		state = State.CHASE
		velocity = Vector2.ZERO

func _deal_attack_damage():
	if attack_hit or player == null:
		return

	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
		attack_hit = true

func _face_player():
	if player:
		sprite.flip_h = player.position.x < position.x
	else:
		sprite.flip_h = direction < 0

func take_damage(amount):
	HEALTH -= amount
	hp_bar.value = HEALTH
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if HEALTH <= 0:
		die()

func die():
	queue_free()
