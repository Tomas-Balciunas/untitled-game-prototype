extends Node

var maps = {
	"area_00": load("res://maps/hub/starting_area.tres"),
	"crypt_00": load("res://maps/crypt/crypt_00.tres")
}

var arenas = {
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

func is_transition(tile_data: Dictionary):
	return "transition" in tile_data and tile_data["transition"] 
