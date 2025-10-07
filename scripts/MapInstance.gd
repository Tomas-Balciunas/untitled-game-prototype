extends Node

var map_id: String
var current_map_name: String = ""
var theme: String = ""
var map_data: PackedScene
var player_position = Vector2i()
var player_previous_position = Vector2i()
var player_facing = Vector3.FORWARD
var triggered_events := {}
var encounters := {}
var cleared_encounters: Dictionary = {}
var transitions := {}
var available_enemies: Array[CharacterResource] = []

func hydrate_from_resource(map_resource):
	map_id = map_resource.id
	current_map_name = map_resource.name
	map_data = map_resource.data
	player_position = map_resource.start_pos
	player_previous_position = player_position
	cleared_encounters[map_id] = []
	available_enemies = map_resource.available_enemies
	
func hydrate_from_load(load_data):
	if load_data.has("dungeon"):
		var dungeon = load_data["dungeon"]
		player_previous_position = dungeon["player_position"]
		player_facing = dungeon["player_facing"]
		cleared_encounters = dungeon["cleared_encounters"]

func update_player_position(pos: Vector2i, facing: Vector3):
	player_previous_position = player_position
	player_position = pos
	player_facing = facing
	
	for c in PartyManager.members:
		var event = TriggerEvent.new()
		event.trigger = EffectTriggers.ON_TURN_END
		event.actor = c
		EffectRunner.process_trigger(event)
		
func add_encounter(data: EncounterData):
	if not encounters.has(map_id):
		encounters[map_id] = {}

	if encounters[map_id].has(data.id):
		return
	
	encounters[map_id][data.id] = data
	
func get_encounter(id: String):
	if encounters.has(map_id):
		if encounters[map_id].has(id):
			return encounters[map_id][id]
			
	return null

func mark_encounter_cleared(encounter_id: String) -> void:
	cleared_encounters[map_id].append(encounter_id)

func is_encounter_cleared(encounter_id: String) -> bool:
	if not cleared_encounters.has(map_id):
		return false
	return cleared_encounters[map_id].has(encounter_id)

func to_dict() -> Dictionary:
	var dungeon_data := {
		"id": map_id,
		"player_position": player_position,
		"player_facing": player_facing,
		"cleared_encounters": cleared_encounters,
		"encounters": encounters
	}
	
	return { "dungeon": dungeon_data }
	
func from_dict(data: Dictionary):
	if data.has("dungeon"):
		var dungeon = data["dungeon"].duplicate(true)
		player_position = dungeon["player_position"]
		player_facing = dungeon["player_facing"]
		cleared_encounters = dungeon["cleared_encounters"]
		encounters = dungeon["encounters"]
