extends Node2D


func _ready() -> void:
	GameAudio.play_music("menu", 0.5)


func save_game() -> void:
	SaveManager.save_from_game(self)
