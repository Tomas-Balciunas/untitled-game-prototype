extends Node
class_name RaceRegistry

static var races: Array[Race] = []

static func get_all() -> Array[Race]:
	for file in DirAccess.get_files_at("res://characters/_race/"):
		if file.ends_with(".tres") and not file.begins_with("_Unknown"):
			var res: Race = load("res://characters/_race/" + file)
			races.append(res)
	return races

static func type_to_string(value: int) -> String:
	for key: String in Race.Name.keys():
		if Race.Name[key] == value:	
			return key.capitalize()
	return "Unknown"
	
static func get_by_name(value: String) -> Resource:
	for file in DirAccess.get_files_at("res://characters/_race/"):
		if file.ends_with(".tres") and file.begins_with(value):
			var res: Race = load("res://characters/_race/" + file)
			
			return res
		
	return null
