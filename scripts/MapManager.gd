extends Node

var maps = {
	"start_area_00": load("res://maps/starting_area.tres")
}

var arenas = {
	"default": preload("res://maps/arena/default/arena_default.tscn")
}

func get_map(id: String) -> MapData:
	if maps.has(id):
		return maps[id]
	return null
