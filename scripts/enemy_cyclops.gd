extends CharacterBody2D

enum State { PATROL, CHASE, ATTACK }

var MAX_HEALTH = 5
var HEALTH = 5

var speed = 65
var chase_speed = 70
var attack_lunge_speed = 110

var direction = 1
var player = null
var state = State.PATROL

var detect_range = 250
var lose_range = 350

var attack_cooldown = 1.2
var attack_cooldown_timer = 0.0
var attack_windup = 0.2
var attack_lunge_time = 0.35
var attack_recoil_time = 0.28
var attack_recoil_speed = 75
var attack_timer = 0.0
var attack_lunging = false
var attack_hit = false
var attack_damage = 2

var pathfinding: Node = null
var current_path: PackedVector2Array = []
var path_index := 0
var path_recalc_timer := 0.0
var path_recalc_interval := 0.75
var path_force_cooldown_timer := 0.0
var path_force_cooldown := 0.6
var move_target := Vector2.ZERO
var patrol_target := Vector2.ZERO
var patrol_recalc_timer := 0.0
var stuck_timer := 0.0

var malfunction_timer := 0.0
var stutter_timer := 0.0
var speed_jitter := 1.0
var heading_wobble := 0.0
var is_stuttering := false

@onready var hp_bar = $HealthBar
@onready var sprite = $AnimatedSprite2D

func _ready():
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = HEALTH
	pathfinding = get_tree().current_scene.get_node("Pathfinding")
	patrol_target = global_position + Vector2(direction * 80, 0)
	malfunction_timer = randf_range(0.0, 1.0)


func _physics_process(delta):
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta

	path_recalc_timer -= delta
	path_force_cooldown_timer = max(path_force_cooldown_timer - delta, 0.0)
	patrol_recalc_timer -= delta
	_update_malfunction(delta)

	_update_player_reference()
	_update_state()

	match state:
		State.PATROL:
			_patrol(delta)
		State.CHASE:
			_chase_player()
		State.ATTACK:
			_attack_player(delta)

	velocity = _apply_malfunction(velocity)

	var previous_position := global_position
	move_and_slide()
	_update_sprite_glitch()
	_update_animation()
	if state == State.PATROL:
		sprite.flip_h = direction < 0
	else:
		_face_player()
	_handle_stuck(previous_position, delta)

	if state == State.PATROL and get_slide_collision_count() > 0:
		direction *= -1
		patrol_target = global_position + Vector2(direction * 80, 0)
		patrol_recalc_timer = 0.0
		_clear_path()


func _update_player_reference():
	var potential_player = get_tree().get_first_node_in_group("player")
	if potential_player == null:
		player = null
		return

	var distance = global_position.distance_to(potential_player.global_position)

	if player == null:
		if distance <= detect_range:
			player = potential_player
	elif distance > lose_range:
		player = null
		_clear_path()


func _update_state():
	if player == null:
		if state != State.ATTACK or attack_timer <= 0.0:
			state = State.PATROL
		return

	var distance = global_position.distance_to(player.global_position)

	if state == State.ATTACK:
		return

	if distance <= _get_attack_start_range() and attack_cooldown_timer <= 0.0:
		state = State.ATTACK
		attack_timer = attack_windup + attack_lunge_time + attack_recoil_time
		attack_lunging = false
		attack_hit = false
		velocity = Vector2.ZERO
		_clear_path()
	elif distance <= detect_range:
		state = State.CHASE
	else:
		state = State.PATROL


func _patrol(_delta):
	if patrol_recalc_timer <= 0.0 or global_position.distance_to(patrol_target) < 12.0:
		patrol_target = global_position + Vector2(direction * 80, 0)
		patrol_recalc_timer = 2.0
		_request_path(patrol_target, true)

	_move_along_path(speed)
	sprite.flip_h = direction < 0


func _chase_player():
	if player == null:
		velocity = Vector2.ZERO
		return

	var to_player = player.global_position - global_position
	_face_player()

	_request_path(player.global_position)
	if current_path.is_empty():
		velocity = to_player.normalized() * chase_speed
	else:
		_move_along_path(chase_speed)


func _attack_player(delta):
	if player == null:
		state = State.PATROL
		velocity = Vector2.ZERO
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	_face_player()
	attack_timer -= delta

	if attack_timer > attack_lunge_time + attack_recoil_time:
		velocity = Vector2.ZERO
	elif attack_timer > attack_recoil_time:
		if not attack_lunging:
			attack_lunging = true
		velocity = to_player.normalized() * attack_lunge_speed
		if _can_hit_player():
			_deal_attack_damage()
	elif attack_timer > 0.0:
		if distance > 8.0:
			velocity = -to_player.normalized() * attack_recoil_speed
		else:
			velocity = Vector2.ZERO
	else:
		attack_cooldown_timer = attack_cooldown
		state = State.CHASE
		velocity = Vector2.ZERO
		attack_lunging = false


func _request_path(target: Vector2, force := false) -> void:
	if pathfinding == null:
		return

	if force and path_force_cooldown_timer > 0.0:
		return

	if not force and path_recalc_timer > 0.0 and not current_path.is_empty():
		return

	if not force and move_target.distance_to(target) < 24.0 and not current_path.is_empty():
		return

	move_target = target
	current_path = pathfinding.find_path(global_position, target)
	path_index = 0
	path_recalc_timer = path_recalc_interval
	if force:
		path_force_cooldown_timer = path_force_cooldown


func _move_along_path(move_speed: float) -> void:
	if current_path.is_empty():
		velocity = Vector2.ZERO
		return

	while path_index < current_path.size() - 1 and global_position.distance_to(current_path[path_index]) < 8.0:
		path_index += 1

	var next_point = current_path[path_index]
	var direction_to_point = next_point - global_position

	if direction_to_point.length() < 4.0:
		if path_index >= current_path.size() - 1:
			velocity = Vector2.ZERO
			return
		path_index += 1
		next_point = current_path[path_index]
		direction_to_point = next_point - global_position

	if direction_to_point.length() < 1.0:
		velocity = Vector2.ZERO
		return

	velocity = direction_to_point.normalized() * move_speed


func _handle_stuck(previous_position: Vector2, delta: float) -> void:
	if state == State.ATTACK or velocity.length() < 4.0:
		stuck_timer = 0.0
		return

	var moved := global_position.distance_to(previous_position)
	if moved < velocity.length() * delta * 0.25:
		stuck_timer += delta
		if stuck_timer >= 0.5:
			_request_path(move_target, true)
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0


func _clear_path() -> void:
	current_path.clear()
	path_index = 0


func _deal_attack_damage():
	if attack_hit or player == null:
		return

	if not _can_hit_player():
		return

	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
		attack_hit = true


func _can_hit_player() -> bool:
	if player == null:
		return false
	return global_position.distance_to(player.global_position) <= _get_hit_range()


func _get_hit_range() -> float:
	var player_shape := player.get_node("CollisionShape2D").shape as RectangleShape2D
	var enemy_shape := $CollisionShape2D.shape as RectangleShape2D
	var player_half: Vector2 = player_shape.size * player.scale * 0.5
	var enemy_half: Vector2 = enemy_shape.size * scale * 0.5
	return (player_half + enemy_half).length() * 0.95


func _get_attack_start_range() -> float:
	return _get_hit_range() + 8.0


func _face_player():
	if player:
		sprite.flip_h = player.global_position.x > global_position.x
	else:
		sprite.flip_h = direction > 0


func _update_animation() -> void:
	var anim := "idle"
	if state == State.ATTACK:
		anim = "attack"

	if sprite.animation != anim:
		sprite.play(anim)


func _update_malfunction(delta: float) -> void:
	malfunction_timer -= delta
	if malfunction_timer <= 0.0:
		malfunction_timer = randf_range(0.25, 1.0)
		if randf() < 0.2:
			is_stuttering = true
			stutter_timer = randf_range(0.08, 0.3)
		speed_jitter = randf_range(0.6, 1.2)
		heading_wobble = randf_range(-0.5, 0.5)

	if is_stuttering:
		stutter_timer -= delta
		if stutter_timer <= 0.0:
			is_stuttering = false


func _apply_malfunction(base_velocity: Vector2) -> Vector2:
	if state == State.ATTACK:
		return base_velocity

	if is_stuttering:
		return Vector2.ZERO

	if base_velocity.length() < 1.0:
		if randf() < 0.02:
			return Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * 10
		return base_velocity

	var move_dir := base_velocity.normalized().rotated(heading_wobble * 0.12)
	return move_dir * base_velocity.length() * speed_jitter


func _update_sprite_glitch() -> void:
	if is_stuttering:
		sprite.rotation = randf_range(-0.15, 0.15)
	elif velocity.length() > 8.0:
		sprite.rotation = lerp(sprite.rotation, heading_wobble * 0.1, 0.25)
	else:
		sprite.rotation = lerp(sprite.rotation, 0.0, 0.2)


func take_damage(amount):
	HEALTH -= amount
	hp_bar.value = HEALTH
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if HEALTH <= 0:
		die()


func die():
	var game := get_tree().current_scene as Node2D
	if game != null and game.has_method("save_game"):
		game.save_game()
	queue_free()
