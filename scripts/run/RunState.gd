extends Node


var current: Run = Run.new()


func begin() -> void:
	current = Run.new()

func load_from(state: Dictionary) -> void:
	current = Run.new()
	current.game_load(state)
