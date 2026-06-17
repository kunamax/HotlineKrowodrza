extends CanvasLayer

const ARROW_MARGIN := 72.0
const ARROW_RADIUS := 0.42
const BOSS_DOOR_NAME := "DoorToBossRoom"
const KEY_NODE_NAME := "Key"
const NEAR_TARGET_DISTANCE := 90.0
const TUTORIAL_DURATION := 12.0
const DUNGEON_SCENE_FRAGMENT := "game.tscn"

@onready var key_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/KeyCount
@onready var grenade_count_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/GrenadeCount
@onready var shield_label: Label = $MarginContainer/VBoxContainer/HBoxContainer/ShieldLabel
@onready var shield_icon: TextureRect = $MarginContainer/VBoxContainer/HBoxContainer/ShieldIcon
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/HealthRow/HealthBar
@onready var health_value_label: Label = $MarginContainer/VBoxContainer/HealthRow/HealthValue
@onready var objective_label: Label = $ObjectiveLayer/ObjectiveLabel
@onready var objective_arrow: Control = $ObjectiveLayer/ObjectiveArrow
@onready var minimap_panel: PanelContainer = $MinimapLayer/MinimapPanel
@onready var tutorial_panel: PanelContainer = $TutorialLayer/TutorialPanel
@onready var tutorial_label: Label = $TutorialLayer/TutorialPanel/TutorialLabel

var _player: Node2D = null
var _boss_target: Node2D = null
var _tutorial_time_left := 0.0


func _ready() -> void:
	tutorial_panel.hide()
	minimap_panel.hide()
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_boss_target = _find_boss_target()
	_connect_player_signals()
	objective_arrow.pivot_offset = objective_arrow.size * 0.5
	_update_dungeon_widgets()


func _process(delta: float) -> void:
	_update_objective_arrow()
	_update_tutorial(delta)


func show_tutorial() -> void:
	if not _is_dungeon_scene():
		return
	_tutorial_time_left = TUTORIAL_DURATION
	tutorial_panel.show()
	tutorial_panel.modulate = Color(1, 1, 1, 1)


func _connect_player_signals() -> void:
	if _player == null:
		return

	if _player.has_signal("keys_changed"):
		_player.keys_changed.connect(_on_keys_changed)

	if _player.has_signal("shield_changed"):
		_player.shield_changed.connect(_on_shield_changed)

	if _player.has_signal("health_changed"):
		_player.health_changed.connect(_on_health_changed)

	if _player.has_signal("grenades_changed"):
		_player.grenades_changed.connect(_on_grenades_changed)

	_on_keys_changed(_player.keys)
	_on_grenades_changed(_player.grenades, _player.MAX_GRENADES)
	_on_shield_changed(_player.shield_active)
	_on_health_changed(_player.HEALTH, _player.MAX_HEALTH)


func _is_dungeon_scene() -> bool:
	var scene := get_tree().current_scene
	return scene != null and String(scene.scene_file_path).contains(DUNGEON_SCENE_FRAGMENT)


func _update_dungeon_widgets() -> void:
	minimap_panel.visible = _is_dungeon_scene() and not SaveManager.is_boss_door_used()


func _find_boss_target() -> Node2D:
	var game := get_tree().current_scene as Node2D
	if game == null:
		return null
	return game.get_node_or_null(BOSS_DOOR_NAME) as Node2D


func _find_key_target() -> Node2D:
	var game := get_tree().current_scene as Node2D
	if game == null:
		return null
	return game.get_node_or_null(KEY_NODE_NAME) as Node2D


func _player_has_key() -> bool:
	if _player == null:
		return false
	var key_count: Variant = _player.get("keys")
	return typeof(key_count) in [TYPE_INT, TYPE_FLOAT] and key_count > 0


func _get_objective_target() -> Node2D:
	if _player_has_key():
		return _boss_target
	return _find_key_target()


func _update_objective_arrow() -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _boss_target == null or not is_instance_valid(_boss_target):
		_boss_target = _find_boss_target()

	var show_arrow := _should_show_objective()
	objective_arrow.visible = show_arrow
	objective_label.visible = show_arrow
	if not show_arrow:
		return

	var target := _get_objective_target()
	if target == null or not is_instance_valid(target):
		objective_arrow.visible = false
		objective_label.visible = false
		return

	var target_pos := _get_target_position(target)
	var to_target: Vector2 = target_pos - _player.global_position
	var seeking_key := not _player_has_key()

	if to_target.length() <= NEAR_TARGET_DISTANCE:
		objective_arrow.visible = false
		if seeking_key:
			objective_label.text = "KEY — pick it up"
		else:
			objective_label.text = "BOSS ROOM — press [F]"
		return

	objective_label.text = "FIND KEY" if seeking_key else "BOSS ROOM"
	var viewport_size := get_viewport().get_visible_rect().size
	var center := viewport_size * 0.5
	var direction := to_target.normalized()
	var edge_pos := center + direction * minf(viewport_size.x, viewport_size.y) * ARROW_RADIUS
	edge_pos.x = clampf(edge_pos.x, ARROW_MARGIN, viewport_size.x - ARROW_MARGIN)
	edge_pos.y = clampf(edge_pos.y, ARROW_MARGIN, viewport_size.y - ARROW_MARGIN)

	objective_arrow.position = edge_pos - objective_arrow.size * 0.5
	objective_arrow.rotation = direction.angle()


func _should_show_objective() -> bool:
	if _player == null:
		return false
	if SaveManager.is_boss_door_used():
		return false
	if not _is_dungeon_scene():
		return false
	if _player_has_key():
		return _boss_target != null
	return _find_key_target() != null


func _get_target_position(target: Node2D) -> Vector2:
	if target.has_method("get_objective_position"):
		return target.call("get_objective_position")
	return target.global_position


func _update_tutorial(delta: float) -> void:
	if not tutorial_panel.visible:
		return

	_tutorial_time_left -= delta
	if _tutorial_time_left <= 0.0:
		tutorial_panel.hide()
		return

	var alpha := clampf(_tutorial_time_left / 2.0, 0.0, 1.0)
	tutorial_panel.modulate = Color(1, 1, 1, alpha)


func _on_keys_changed(count: int) -> void:
	key_count_label.text = "x %d" % count
	key_count_label.modulate = Color(1, 1, 1, 1) if count > 0 else Color(0.55, 0.55, 0.55, 1)


func _on_grenades_changed(current: int, _maximum: int) -> void:
	grenade_count_label.text = "x %d" % current
	grenade_count_label.modulate = Color(1, 0.72, 0.35, 1) if current > 0 else Color(0.55, 0.55, 0.55, 1)


func _on_shield_changed(active: bool) -> void:
	shield_label.visible = active
	shield_icon.visible = active


func _on_health_changed(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_value_label.text = "%d/%d" % [current, maximum]
