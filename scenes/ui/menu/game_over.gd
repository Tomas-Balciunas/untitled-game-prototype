extends Node

const MAIN_MENU = preload("uid://cy17x515s2gnd")


func _on_button_pressed() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU)
