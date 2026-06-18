extends Node

const FLASH_LAYER := 90

var _shake_strength := 0.0
var _camera: Camera2D = null
var _flash_rect: ColorRect = null
var _hitstop_active := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_flash_layer()
	call_deferred("_refresh_camera")


func _process(delta: float) -> void:
	if _camera == null:
		_refresh_camera()

	if _shake_strength > 0.01:
		_shake_strength = maxf(_shake_strength - 8.0 * delta, 0.0)
		if _camera != null:
			var jitter := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
			_camera.offset = jitter * _shake_strength
	elif _camera != null and _camera.offset != Vector2.ZERO:
		_camera.offset = Vector2.ZERO


func _setup_flash_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = FLASH_LAYER
	layer.name = "CombatFlashLayer"
	add_child(layer)

	_flash_rect = ColorRect.new()
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.color = Color(1, 1, 1, 0)
	layer.add_child(_flash_rect)


func _refresh_camera() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		_camera = null
		return
	_camera = player.get_node_or_null("Camera2D") as Camera2D


func shake(amount: float = 3.0) -> void:
	if GameSettings != null and not GameSettings.screen_shake_enabled:
		return
	_shake_strength = maxf(_shake_strength, amount)
	_refresh_camera()


func flash(color: Color, duration := 0.08) -> void:
	if _flash_rect == null:
		return

	_flash_rect.color = color
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, duration)


func brief_hitstop(duration := 0.05, time_scale := 0.08) -> void:
	if _hitstop_active or get_tree().paused:
		return

	_hitstop_active = true
	var previous_scale := Engine.time_scale
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = previous_scale
	_hitstop_active = false


func on_player_hit() -> void:
	shake(3.5)
	flash(Color(1.0, 0.2, 0.2, 0.35))
	GameAudio.play_sfx("hit", randf_range(0.92, 1.0))


func on_enemy_hit() -> void:
	shake(1.6)
	flash(Color(1.0, 1.0, 1.0, 0.12))


func on_enemy_killed() -> void:
	shake(4.5)
	flash(Color(1.0, 0.85, 0.2, 0.22))
	brief_hitstop()
