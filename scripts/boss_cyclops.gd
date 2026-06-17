extends "res://scripts/enemy_cyclops.gd"

signal phase_changed(phase: int)
signal health_changed(current: int, maximum: int)

enum Phase { ONE, TWO }

const PHASE_TWO_THRESHOLD := 0.5

var phase := Phase.ONE

var _entered_phase_two := false
var _attack_windup_active := false
var _base_sprite_scale := Vector2.ONE

@onready var _telegraph_line: Line2D = $TelegraphLine


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	_base_sprite_scale = sprite.scale
	if _telegraph_line != null:
		_telegraph_line.visible = false
	health_changed.emit(HEALTH, MAX_HEALTH)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _telegraph_line != null and _telegraph_line.visible and player != null:
		_update_telegraph_line()


func _on_damage_taken(_amount: int) -> void:
	health_changed.emit(HEALTH, MAX_HEALTH)
	if _entered_phase_two:
		return
	if float(HEALTH) / float(MAX_HEALTH) > PHASE_TWO_THRESHOLD:
		return
	_enter_phase_two()


func _enter_phase_two() -> void:
	_entered_phase_two = true
	phase = Phase.TWO
	attack_cooldown *= 0.6
	attack_windup *= 0.7
	chase_speed = int(chase_speed * 1.25)
	attack_lunge_speed = int(attack_lunge_speed * 1.15)
	detect_range += 40
	modulate = Color(1.0, 0.65, 0.65)
	GameAudio.play_sfx("boss_roar", 0.95)
	phase_changed.emit(phase)


func _attack_player(delta: float) -> void:
	if player == null:
		state = State.PATROL
		velocity = Vector2.ZERO
		_clear_telegraph()
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	_face_player()
	attack_timer -= delta

	if attack_timer > attack_lunge_time + attack_recoil_time:
		if not _attack_windup_active:
			_attack_windup_active = true
			_on_attack_windup_started()
		velocity = Vector2.ZERO
	elif attack_timer > attack_recoil_time:
		if _attack_windup_active:
			_attack_windup_active = false
			_on_attack_windup_ended()
		if not attack_lunging:
			attack_lunging = true
		velocity = to_player.normalized() * attack_lunge_speed
		if _can_hit_player():
			_deal_attack_damage()
	elif attack_timer > 0.0:
		_clear_telegraph()
		if distance > 8.0:
			velocity = -to_player.normalized() * attack_recoil_speed
		else:
			velocity = Vector2.ZERO
	else:
		attack_cooldown_timer = attack_cooldown
		state = State.CHASE
		velocity = Vector2.ZERO
		attack_lunging = false
		_clear_telegraph()


func _on_attack_windup_started() -> void:
	if _telegraph_line != null:
		_telegraph_line.visible = true
		_update_telegraph_line()
	sprite.modulate = Color(1.0, 0.35, 0.35)
	var pulse := create_tween()
	pulse.set_loops(2)
	pulse.tween_property(sprite, "scale", _base_sprite_scale * 1.1, max(attack_windup * 0.35, 0.05))
	pulse.tween_property(sprite, "scale", _base_sprite_scale, max(attack_windup * 0.35, 0.05))


func _on_attack_windup_ended() -> void:
	_clear_telegraph()
	if phase == Phase.TWO:
		sprite.modulate = Color(1.0, 0.65, 0.65)
	else:
		sprite.modulate = Color.WHITE


func _clear_telegraph() -> void:
	_attack_windup_active = false
	if _telegraph_line != null:
		_telegraph_line.visible = false
	sprite.scale = _base_sprite_scale


func _update_telegraph_line() -> void:
	if player == null or _telegraph_line == null:
		return
	_telegraph_line.points = [Vector2.ZERO, to_local(player.global_position)]
