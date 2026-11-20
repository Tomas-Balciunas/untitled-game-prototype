extends RefCounted
class_name HazardRegistry


const ROOT: String = "res://hazard"

static var hazards: Dictionary = {}
static var loaded: bool = false

static func get_hazard(id: String) -> Hazard:
	_ensure_loaded()
	if not hazards.has(id):
		push_error("HazardRegistry: unknown hazard '%s'" % id)
		return null
	return hazards[id]

static func has_hazard(id: String) -> bool:
	_ensure_loaded()
	return hazards.has(id)

static func _ensure_loaded() -> void:
	if loaded:
		return
	loaded = true
	_scan(ROOT)

static func _scan(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("HazardRegistry: cannot open %s" % path)
		return

	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		var full: String = path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan(full)
		else:
			full = full.trim_suffix(".remap")
			if full.ends_with(".tres") or full.ends_with(".res"):
				_register(ResourceLoader.load(full), full)
		entry = dir.get_next()
	dir.list_dir_end()

static func _register(res: Resource, path: String) -> void:
	if not res is Hazard:
		return
	var hazard: Hazard = res
	if hazard.id.is_empty():
		push_warning("HazardRegistry: hazard without id skipped: %s" % path)
		return
	if hazards.has(hazard.id):
		push_warning("HazardRegistry: duplicate hazard id '%s' (%s)" % [hazard.id, path])
	hazards[hazard.id] = hazard
