extends Node2D


func save_game() -> void:
	SaveManager.save_from_game(self)
