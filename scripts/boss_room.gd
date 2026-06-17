extends Node2D

const AUTOSAVE_INTERVAL := 10.0
const ENDING_SCENE := "res://scenes/ending_scene.tscn"
const INTRO_HOLD_TIME := 2.0

var _autosave_timer: Timer
var _ending_started := false
var _intro_active := false
var _loaded_from_save := false

@onready var _death_menu: Control = $DeathLayer/you_died_menu
@onready var _boss: Node = $Boss
@onready var _player: CharacterBody2D = $Player
@onready var _entrance_blocker: StaticBody2D = $EntranceBlocker
@onready var _boss_hp_bar: ProgressBar = $BossHudLayer/BossHealthBar
@onready var _phase_label: Label = $BossHudLayer/PhaseLabel


func _ready() -> void:
	_setup_autosave()
	_loaded_from_save = SaveManager.load_on_scene_start

	if _loaded_from_save:
		SaveManager.load_into_game(self)
		SaveManager.clear_load_on_start()
	else:
		save_game()

	_setup_boss_hud()
	_watch_boss_state()
	GameAudio.stop_music(0.2)

	if _loaded_from_save:
		_skip_intro()
		GameAudio.play_music("boss", 0.4)
	else:
		_play_boss_intro()


func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = AUTOSAVE_INTERVAL
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _setup_boss_hud() -> void:
	if _boss == null:
		return

	if _boss.has_signal("health_changed"):
		_boss.health_changed.connect(_on_boss_health_changed)
		_on_boss_health_changed(_boss.HEALTH, _boss.MAX_HEALTH)

	if _boss.has_signal("phase_changed"):
		_boss.phase_changed.connect(_on_boss_phase_changed)


func _on_boss_health_changed(current: int, maximum: int) -> void:
	_boss_hp_bar.max_value = maximum
	_boss_hp_bar.value = current


func _on_boss_phase_changed(_phase: int) -> void:
	_phase_label.show()
	await get_tree().create_timer(1.2).timeout
	_phase_label.hide()


func _on_autosave_timeout() -> void:
	if _ending_started or _intro_active:
		return
	save_game()


func save_game() -> void:
	SaveManager.save_from_game(self)


func show_death_menu() -> void:
	SaveManager.delete_save()
	if _autosave_timer != null:
		_autosave_timer.stop()
	_death_menu.show_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _watch_boss_state() -> void:
	if _boss == null:
		_on_boss_defeated()
		return

	_boss.tree_exited.connect(_on_boss_defeated)


func _on_boss_defeated() -> void:
	if _ending_started:
		return

	_ending_started = true
	GameAudio.stop_music(0.6)
	SaveManager.delete_save()
	if _autosave_timer != null:
		_autosave_timer.stop()
	await get_tree().create_timer(0.7).timeout
	get_tree().change_scene_to_file(ENDING_SCENE)


func _skip_intro() -> void:
	var fade_rect: ColorRect = $IntroLayer/FadeRect
	var intro_label: Label = $IntroLayer/IntroLabel
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro_label.hide()


func _play_boss_intro() -> void:
	_intro_active = true
	_entrance_blocker.set_deferred("collision_layer", 1)

	if _boss != null:
		_boss.set_process(false)
		_boss.set_physics_process(false)
	if _player != null:
		_player.set_physics_process(false)

	var fade_layer := $IntroLayer
	var fade_rect: ColorRect = fade_layer.get_node("FadeRect")
	var intro_label: Label = fade_layer.get_node("IntroLabel")

	fade_rect.color = Color(0, 0, 0, 1)
	intro_label.show()

	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "color:a", 0.55, 0.9)
	await fade_in.finished

	await get_tree().create_timer(INTRO_HOLD_TIME).timeout

	intro_label.hide()
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "color:a", 0.0, 0.6)
	await fade_out.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _boss != null:
		_boss.set_process(true)
		_boss.set_physics_process(true)
	if _player != null:
		_player.set_physics_process(true)

	_intro_active = false
	GameAudio.play_music("boss", 1.0)
