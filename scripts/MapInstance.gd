extends Node

signal map_transition_finish()

var map_id: String = ""
var current_map_name: String = ""
var theme: String = ""
var map_data = []
var player_position = Vector2i()
var triggered_events = {}
var cleared_encounters = {}
var transitions = {}

func hydrate_from_resource(map_resource):
	map_id = map_resource.id
	current_map_name = map_resource.name
	theme = map_resource.theme
	map_data = map_resource.data
	player_position = map_resource.start_pos

func update_player_position(pos: Vector2i):
	print(player_position)
	player_position = pos

#func mark_event_triggered(event_id: String):
	#triggered_events[event_id] = true
#
#func is_event_triggered(event_id: String) -> bool:
	#return triggered_events.has(event_id)
#
#func mark_encounter_cleared(encounter_id: String):
	#cleared_encounters[encounter_id] = true
#
#func is_encounter_cleared(encounter_id: String) -> bool:
	#return cleared_encounters.has(encounter_id)
