extends Node
class_name RaceRegistry

var races: Dictionary = {}

func _ready():
	for file in DirAccess.get_files_at("res://characters/_race/"):
		if file.ends_with(".tres") and not file.begins_with("_Unknown"):
			var res: Race = load("res://characters/_race/" + file)
			races[res.id] = res

func get_all() -> Array[Race]:
	return races.values()
