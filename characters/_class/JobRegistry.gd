extends Node
class_name JobRegistry

static var jobs: Array[Job] = []

static func get_all() -> Array[Job]:
	jobs.clear()
	for dir_name in DirAccess.get_directories_at("res://characters/_class/"):
		if not dir_name.begins_with("class_"):
			continue
		var dir_path := "res://characters/_class/%s/" % dir_name
		for file in DirAccess.get_files_at(dir_path):
			if file.begins_with("class_") and file.ends_with(".tres"):
				jobs.append(load(dir_path + file))
	return jobs

static func type_to_string(value: int) -> String:
	for key: String in Job.Name.keys():
		if Job.Name[key] == value:
			return key.capitalize()
	return "Unknown"

static func get_by_name(value: String) -> Job:
	var dir_name := "class_" + value.to_lower()
	var path := "res://characters/_class/%s/%s.tres" % [dir_name, dir_name]
	if ResourceLoader.exists(path):
		return load(path)
	push_error("Job resource not found for '%s'" % value)
	return null
