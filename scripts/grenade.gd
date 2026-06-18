extends Area2D

const SPEED := 165.0
const FUSE_TIME := 1.35
const EXPLOSION_RADIUS := 52.0
const EXPLOSION_DAMAGE := 3

var _velocity := Vector2.ZERO
var _fuse := FUSE_TIME
var _exploded := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func launch(from: Vector2, direction: Vector2) -> void:
	global_position = from
	_velocity = direction.normalized() * SPEED
	rotation = _velocity.angle()


func _physics_process(delta: float) -> void:
	if _exploded:
		return

	global_position += _velocity * delta
	_fuse -= delta
	if _fuse <= 0.0:
		_explode()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		return
	_explode()


func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	GameAudio.play_sfx("enemy_death", 0.72)
	CombatFeel.shake(5.5)
	CombatFeel.flash(Color(1.0, 0.55, 0.15, 0.35), 0.12)

	var center := global_position
	for node in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(node):
			continue
		if node.global_position.distance_to(center) > EXPLOSION_RADIUS:
			continue
		if node.has_method("take_damage"):
			node.take_damage(EXPLOSION_DAMAGE)

	queue_free()
