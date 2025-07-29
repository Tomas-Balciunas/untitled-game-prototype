extends Node

@onready var level_up_screen = get_tree().get_root().get_node("Main/LevelUp")

var to_level_up: Array[CharacterInstance] = []

func on_rest_button_pressed():
	to_level_up = PartyManager.members.filter(func(c): return c.current_experience > c.experience_to_next_level)
	next_character_level_up()

func next_character_level_up():
	if to_level_up.size() > 0:
		level_up_screen.show_for_character(to_level_up.pop_front())
