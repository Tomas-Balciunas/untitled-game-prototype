extends Node
class_name GenderRegistry

var genders: Array[Gender] = []

func _ready():
	for file in DirAccess.get_files_at("res://characters/_gender/"):
		if file.ends_with(".tres") and not file.begins_with("_Unknown"):
			var res: Gender = load("res://characters/_gender/" + file)
			genders.append(res)

func get_all() -> Array[Gender]:
	return genders
