extends Node

const SETTINGS_PATH := "user://settings.json"

signal settings_changed

var music_volume: float = 0.85
var sfx_volume: float = 1.0
var screen_shake_enabled: bool = true
var fullscreen_enabled: bool = false

var _loaded := false


func _ready() -> void:
	load_settings()
	_apply_all()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		_loaded = true
		return

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		_loaded = true
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_loaded = true
		return

	music_volume = clampf(float(parsed.get("music_volume", music_volume)), 0.0, 1.0)
	sfx_volume = clampf(float(parsed.get("sfx_volume", sfx_volume)), 0.0, 1.0)
	screen_shake_enabled = bool(parsed.get("screen_shake_enabled", screen_shake_enabled))
	fullscreen_enabled = bool(parsed.get("fullscreen_enabled", fullscreen_enabled))
	_loaded = true


func save_settings() -> void:
	var data := {
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"screen_shake_enabled": screen_shake_enabled,
		"fullscreen_enabled": fullscreen_enabled,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_music_volume()
	settings_changed.emit()
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()
	settings_changed.emit()
	save_settings()


func set_screen_shake_enabled(value: bool) -> void:
	screen_shake_enabled = value
	settings_changed.emit()
	save_settings()


func set_fullscreen_enabled(value: bool) -> void:
	fullscreen_enabled = value
	_apply_fullscreen()
	settings_changed.emit()
	save_settings()


func _apply_all() -> void:
	_apply_music_volume()
	_apply_sfx_volume()
	_apply_fullscreen()


func _apply_music_volume() -> void:
	if GameAudio != null and GameAudio.has_method("set_music_volume_linear"):
		GameAudio.set_music_volume_linear(music_volume)


func _apply_sfx_volume() -> void:
	if GameAudio != null and GameAudio.has_method("set_sfx_volume_linear"):
		GameAudio.set_sfx_volume_linear(sfx_volume)


func _apply_fullscreen() -> void:
	if fullscreen_enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
