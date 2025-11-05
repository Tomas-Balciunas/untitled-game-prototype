extends Node
class_name GenderRegistry

static var genders: Array[Gender] = []

static func get_all() -> Array[Gender]:
	for file in DirAccess.get_files_at("res://characters/_gender/"):
		if file.ends_with(".tres") and not file.begins_with("_Unknown"):
			var res: Gender = load("res://characters/_gender/" + file)
			genders.append(res)
			
	return genders

static func type_to_string(value: int) -> String:
	for key: String in Gender.Name.keys():
		if Gender.Name[key] == value:	
			return key.capitalize()
			
	return "Unknown"

static func get_by_name(value: String) -> Resource:
	for file in DirAccess.get_files_at("res://characters/_gender/"):
		if file.ends_with(".tres") and file.begins_with(value):
			var res: Gender = load("res://characters/_gender/" + file)
			
			return res

	return null
