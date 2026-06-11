extends Node
const SCAN_DIRS := ["res://effect", "res://gear"]

var effects := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	for dir: String in SCAN_DIRS:
		_scan_dir(dir)

func _scan_dir(path: String) -> void:
	var dir := DirAccess.open(path)
	if not dir:
		push_warning("EffectRegistry: cannot open directory %s" % path)
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_scan_dir(path.path_join(entry))
		else:
			_try_register_file(path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()

func _try_register_file(file_path: String) -> void:
	if file_path.ends_with(".remap"):
		file_path = file_path.trim_suffix(".remap")
	if not (file_path.ends_with(".tres") or file_path.ends_with(".res")):
		return
	var res := ResourceLoader.load(file_path)
	if res is Effect:
		if (res as Effect).id.is_empty():
			push_warning("EffectRegistry: effect without id skipped: %s" % file_path)
			return
		register_effect(res)

func register_effect(effect: Effect) -> void:
	if effect.id in effects:
		push_warning("Duplicate effect id: %s" % effect.id)
	effects[effect.id] = effect

func get_effect(id: String) -> Effect:
	if effects.has(id):
		return effects[id]
	return null

func get_all_effects() -> Array:
	return effects.values()
