extends Node

var map_id: String = ""
var current_map_name: String = ""
var theme: String = ""
var map_data: PackedScene
var player_position = Vector2i()
var player_previous_position = Vector2i()
var player_facing = Vector3.FORWARD
var triggered_events := {}
var cleared_encounters: Dictionary = {}
var transitions := {}

func hydrate_from_resource(map_resource):
	map_id = map_resource.id
	current_map_name = map_resource.name
	map_data = map_resource.data
	player_position = map_resource.start_pos
	player_previous_position = player_position
	cleared_encounters[map_id] = []

func update_player_position(pos: Vector2i, facing: Vector3):
	player_previous_position = player_position
	player_position = pos
	player_facing = facing
	
	for c in PartyManager.members:
		c.process_effects("on_turn_end")

func mark_encounter_cleared(id: String, encounter_id: String) -> void:
	cleared_encounters[id].append(encounter_id)

func is_encounter_cleared(id: String, encounter_id: String) -> bool:
	return cleared_encounters[id].has(encounter_id)
