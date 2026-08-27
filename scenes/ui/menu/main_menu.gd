extends Node

const CHARACTER_CREATE = preload("uid://bdlg0nlvckuof")

func _on_start_pressed() -> void:
	RunState.begin()
	get_tree().change_scene_to_packed(CHARACTER_CREATE)
