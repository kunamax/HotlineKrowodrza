extends CharacterBody2D

const SPEED = 85.0
const MUZZLE_OFFSET = 14.0
const GRENADE_COOLDOWN := 2.6
const MAX_GRENADES := 3

var MAX_HEALTH = 60
var HEALTH = 60
var keys := 0
var grenades := MAX_GRENADES
var shield_active := false
var _grenade_cooldown := 0.0

signal keys_changed(key_count: int)
signal shield_changed(active: bool)
signal health_changed(current: int, maximum: int)
signal grenades_changed(current: int, maximum: int)

var Bullet = load("res://scenes/bullet.tscn")
var Grenade = load("res://scenes/grenade.tscn")
var facing_horizontal = 1
var facing_vertical = 1

@onready var sprite = $AnimatedSprite2D
@onready var muzzle = $Muzzle
@onready var hp_bar = $HealthBar

func _ready():
	add_to_group("player")
	hp_bar.max_value = MAX_HEALTH
	hp_bar.value = HEALTH
	health_changed.emit(HEALTH, MAX_HEALTH)
	grenades_changed.emit(grenades, MAX_GRENADES)

func _physics_process(delta: float) -> void:
	_grenade_cooldown = maxf(_grenade_cooldown - delta, 0.0)
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
		GameAudio.play_sfx("shoot", randf_range(0.96, 1.04))
		shoot()

	if Input.is_action_just_pressed("Grenade"):
		throw_grenade()


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


func throw_grenade() -> void:
	if grenades <= 0 or _grenade_cooldown > 0.0:
		return

	var aim_direction: Vector2 = _get_aim_direction()
	var grenade: Node = Grenade.instantiate()
	get_tree().current_scene.add_child(grenade)
	if grenade.has_method("launch"):
		grenade.launch(muzzle.global_position, aim_direction)

	grenades -= 1
	grenades_changed.emit(grenades, MAX_GRENADES)
	GameAudio.play_sfx("shoot", 0.82)
	_grenade_cooldown = GRENADE_COOLDOWN


func add_grenades(amount: int) -> void:
	if amount <= 0:
		return
	grenades = mini(grenades + amount, MAX_GRENADES)
	grenades_changed.emit(grenades, MAX_GRENADES)


func take_damage(amount):
	if shield_active:
		shield_active = false
		shield_changed.emit(false)
		GameAudio.play_sfx("shield")
		modulate = Color(0.55, 0.85, 1.0)
		await get_tree().create_timer(0.12).timeout
		modulate = Color(1, 1, 1)
		return

	HEALTH -= amount
	hp_bar.value = HEALTH
	health_changed.emit(HEALTH, MAX_HEALTH)
	CombatFeel.on_player_hit()
	modulate = Color(1, 0, 0)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)

	if HEALTH <= 0:
		die()


func heal(amount: int) -> void:
	HEALTH = mini(HEALTH + amount, MAX_HEALTH)
	hp_bar.value = HEALTH
	health_changed.emit(HEALTH, MAX_HEALTH)


func grant_shield() -> void:
	shield_active = true
	shield_changed.emit(true)


func set_shield_active(active: bool) -> void:
	shield_active = active
	shield_changed.emit(shield_active)


func set_grenades(count: int) -> void:
	grenades = clampi(count, 0, MAX_GRENADES)
	grenades_changed.emit(grenades, MAX_GRENADES)


func set_keys(count: int) -> void:
	keys = maxi(count, 0)
	keys_changed.emit(keys)


func collect_key() -> void:
	keys += 1
	keys_changed.emit(keys)


func die():
	velocity = Vector2.ZERO
	set_physics_process(false)
	set_process_input(false)

	var game := get_tree().current_scene
	if game != null and game.has_method("show_death_menu"):
		game.show_death_menu()
