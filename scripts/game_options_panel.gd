extends VBoxContainer

signal back_pressed

@onready var back_button: Button = $BackButton
@onready var music_slider: HSlider = $MusicRow/MusicSlider
@onready var music_value_label: Label = $MusicRow/MusicValue
@onready var sfx_slider: HSlider = $SfxRow/SfxSlider
@onready var sfx_value_label: Label = $SfxRow/SfxValue
@onready var shake_check: CheckButton = $ShakeCheck
@onready var fullscreen_check: CheckButton = $FullscreenCheck


func _ready() -> void:
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_STOP
	back_button.pressed.connect(_on_back_pressed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	shake_check.toggled.connect(_on_shake_toggled)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	sync_from_settings()


func sync_from_settings() -> void:
	if GameSettings == null:
		return
	music_slider.set_value_no_signal(GameSettings.music_volume * 100.0)
	sfx_slider.set_value_no_signal(GameSettings.sfx_volume * 100.0)
	shake_check.set_pressed_no_signal(GameSettings.screen_shake_enabled)
	fullscreen_check.set_pressed_no_signal(GameSettings.fullscreen_enabled)
	_update_volume_labels()


func _update_volume_labels() -> void:
	music_value_label.text = "%d%%" % int(music_slider.value)
	sfx_value_label.text = "%d%%" % int(sfx_slider.value)


func _on_back_pressed() -> void:
	back_pressed.emit()


func _on_music_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_music_volume(value / 100.0)
	_update_volume_labels()


func _on_sfx_changed(value: float) -> void:
	if GameSettings != null:
		GameSettings.set_sfx_volume(value / 100.0)
	_update_volume_labels()


func _on_shake_toggled(enabled: bool) -> void:
	if GameSettings != null:
		GameSettings.set_screen_shake_enabled(enabled)


func _on_fullscreen_toggled(enabled: bool) -> void:
	if GameSettings != null:
		GameSettings.set_fullscreen_enabled(enabled)
