extends Node

var maps: Dictionary = {
	"beginning_area_01": preload("uid://c8n1llsvvhonb"),
	"crypt_00": preload("uid://dphnv8sgmui72")
}

var arenas: Dictionary = {
	"arena_default_00": load("res://maps/_arena/default/arena_default_00.tscn")
}

func get_map(id: String) -> Resource:
	if maps.has(id):
		return maps[id]
	return null

func get_arena(id: String) -> PackedScene:
	if arenas.has(id):
		return arenas[id]
	return null
	
func get_map_data(id: String) -> Dictionary:
	var file: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/maps.json"))
	if file.has(id):
		return file[id]
	else:
		push_error("Map with id %s not found" % id)
		return {}

func is_transition(tile_data: Dictionary) -> bool:
	return "transition" in tile_data and tile_data["transition"] 
