extends Node
class_name JobRegistry

static var jobs: Array[Job] = []

static func get_all() -> Array[Job]:
	for file in DirAccess.get_files_at("res://characters/_class/"):
		if file.ends_with(".tres") and not file.begins_with("_Unknown"):
			var res: Job = load("res://characters/_class/" + file)
			jobs.append(res)
			
	return jobs

static func type_to_string(value: int) -> String:
	for key in Job.Name.keys():
		if Job.Name[key] == value:	
			return key.capitalize()
	return "Unknown"

static func get_by_name(value: String) -> Resource:
	for file in DirAccess.get_files_at("res://characters/_class/"):
		if file.ends_with(".tres") and file.begins_with(value):
			var res: Job = load("res://characters/_class/" + file)
			
			return res

	return null
