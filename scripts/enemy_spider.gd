extends CharacterBody2D

var MAX_HEALTH = 3
var HEALTH = 3

var speed = 120
var direction = 1
var player = null

var detect_range = 250
var lose_range = 350
var attack_range = 130

var dash_speed_multiplier = 2.2
var strafe_offset = 70
var dash_cooldown = 1.7
var dash_timer = 0.0
var dash_burst_seconds = 0.18
var dash_burst_left = 0.0

var patrol_timer = 0.0
var patrol_interval = 2.8
var patrol_dir = Vector2.RIGHT

var hit_stun_left = 0.0
var knockback_vel = Vector2.ZERO
var knockback_strength = 240.0
var knockback_decay = 1100.0
var blood_decal_limit = 120
var blood_layer_name = "BloodDecals"
var blood_z_index = 5

@onready var hp_bar = $HealthBar

func _ready():
	motion_mode = MOTION_MODE_FLOATING
	player = get_tree().get_first_node_in_group("player")
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = HEALTH
	_pick_random_patrol_dir()

func _physics_process(delta):
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if dash_timer > 0:
		dash_timer -= delta

	patrol_timer -= delta

	if hit_stun_left > 0:
		hit_stun_left -= delta
		velocity = knockback_vel
		knockback_vel = knockback_vel.move_toward(Vector2.ZERO, knockback_decay * delta)
		move_and_slide()
		return

	if dash_burst_left > 0:
		dash_burst_left -= delta
		move_and_slide()
		if is_on_wall():
			patrol_dir = patrol_dir.bounce(get_wall_normal()).normalized()
			if patrol_dir.length_squared() < 0.01:
				_pick_random_patrol_dir()
		return

	if player == null:
		patrol(delta)
	else:
		chase_player()

	move_and_slide()

	if is_on_wall():
		patrol_dir = patrol_dir.bounce(get_wall_normal()).normalized()
		if patrol_dir.length_squared() < 0.01:
			_pick_random_patrol_dir()

func _pick_random_patrol_dir():
	patrol_dir = Vector2.from_angle(randf() * TAU)

func patrol(delta):
	if patrol_timer <= 0:
		_pick_random_patrol_dir()
		patrol_timer = patrol_interval + randf_range(-0.8, 0.8)

	velocity = patrol_dir * speed

func chase_player():
	var to_player = player.position - position
	var distance = to_player.length()

	if distance < detect_range:
		var lateral = Vector2(-to_player.y, to_player.x)
		if lateral.length_squared() < 0.0001:
			lateral = Vector2.UP
		lateral = lateral.normalized()
		var flank = -sign(to_player.x)
		if flank == 0:
			flank = -sign(to_player.y)
		var desired = player.position + lateral * (strafe_offset * flank)
		var to_target = desired - position
		var move_dir: Vector2
		if to_target.length_squared() > 1.0:
			move_dir = to_target.normalized()
		elif distance > 0.001:
			move_dir = to_player.normalized()
		else:
			move_dir = Vector2.ZERO

		if to_player.x != 0:
			direction = sign(to_player.x)

		velocity = move_dir * speed * 1.2

		if distance < attack_range and dash_timer <= 0 and distance > 0.001:
			var dash_dir = to_player.normalized()
			velocity = dash_dir * speed * dash_speed_multiplier
			dash_timer = dash_cooldown
			dash_burst_left = dash_burst_seconds

	elif distance > lose_range:
		player = null
		patrol(0.0)
	else:
		patrol(0.0)

func _get_blood_layer() -> Node2D:
	var scene_root = get_tree().current_scene
	if scene_root == null:
		return null

	var existing = scene_root.get_node_or_null(blood_layer_name)
	if existing != null and existing is Node2D:
		return existing

	var layer = Node2D.new()
	layer.name = blood_layer_name
	layer.z_as_relative = false
	layer.z_index = blood_z_index
	scene_root.add_child(layer)
	return layer

func _spawn_blood_splat(origin: Vector2, base_radius: float):
	var layer = _get_blood_layer()
	if layer == null:
		return

	if layer.get_child_count() >= blood_decal_limit:
		var oldest = layer.get_child(0)
		oldest.queue_free()

	var splat = Polygon2D.new()
	splat.position = origin + Vector2(randf_range(-7.0, 7.0), randf_range(-7.0, 7.0))
	splat.rotation = randf() * TAU
	splat.color = Color(0.65, 0.05, 0.05, randf_range(0.75, 0.95))

	var points := PackedVector2Array()
	var count = randi_range(8, 12)
	for i in count:
		var t = float(i) / float(count) * TAU
		var wobble = randf_range(0.65, 1.25)
		var radius = base_radius * wobble
		points.append(Vector2(cos(t), sin(t)) * radius)

	splat.polygon = points
	layer.add_child(splat)

func take_damage(amount, hit_dir: Vector2 = Vector2.ZERO):
	HEALTH -= amount
	hp_bar.value = HEALTH
	_spawn_blood_splat(global_position, randf_range(5.0, 9.0))
	hit_stun_left = 0.16
	if hit_dir.length_squared() > 0.0001:
		knockback_vel = hit_dir.normalized() * knockback_strength
	else:
		knockback_vel = Vector2.ZERO
	modulate = Color(1,0,0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1,1,1)

	if HEALTH <= 0:
		die()

func die():
	for i in randi_range(2, 4):
		_spawn_blood_splat(global_position, randf_range(10.0, 16.0))
	queue_free()
