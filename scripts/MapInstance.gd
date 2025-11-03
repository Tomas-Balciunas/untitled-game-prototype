extends Node

var map_id: String
var current_map_name: String = ""
var theme: String = ""
var player_position: Vector2i = Vector2i()
var player_previous_position: Vector2i = Vector2i()
var player_facing: Vector3 = Vector3.FORWARD
var triggered_events := {}
var encounters := {}
var cleared_encounters: Dictionary = {}
var transitions := {}
var available_enemies: Array[CharacterResource] = []
var available_tiers: Array = []
var chest_state: Dictionary = {}

func hydrate_from_resource(map_data: Dictionary) -> void:
	map_id = map_data.id
	current_map_name = map_data.name
	#TODO: more safety checks
	player_position = str_to_var("Vector2i" + map_data.starting_position)
	player_previous_position = player_position
	cleared_encounters[map_id] = []
	available_enemies = CharacterRegistry.get_characters(map_data.available_enemies)
	available_tiers = map_data.gear_tiers
	
func hydrate_from_load(load_data: Dictionary) -> void:
	if load_data.has("dungeon"):
		var dungeon: Dictionary = load_data["dungeon"]
		player_previous_position = str_to_var("Vector2i" + dungeon["player_position"])
		player_position = str_to_var("Vector2i" + dungeon["player_position"])
		player_facing = dungeon["player_facing"]
		cleared_encounters = dungeon["cleared_encounters"]
		chest_state = dungeon["chest_state"]

func update_player_position(pos: Vector2i, facing: Vector3) -> void:
	player_previous_position = player_position
	player_position = pos
	player_facing = facing
	
	for c in PartyManager.members:
		var event: TriggerEvent = TriggerEvent.new()
		event.trigger = EffectTriggers.ON_TURN_END
		event.actor = c
		event.ctx = ActionContext.new()
		EffectRunner.process_trigger(event)
		
func add_encounter(data: EncounterData) -> void:
	if not encounters.has(map_id):
		encounters[map_id] = {}

	if encounters[map_id].has(data.id):
		return
	
	encounters[map_id][data.id] = {
		"id": data.id,
		"enemies": data.enemies.map(func(e): return e.id),
		"arena": data.arena,
		"xp": data.experience_reward
	}
	
func get_encounter(id: String) -> EncounterData:
	if encounters.has(map_id):
		if encounters[map_id].has(id):
			var data: Dictionary = encounters[map_id][id]
			var enc := EncounterData.new()
			var enemeis: Array[CharacterResource] = []
			for i: String in data["enemies"]:
				var e := CharacterRegistry.get_character(id)
				enemeis.append(e)
			enc.id = data["id"]
			enc.enemies = enemeis
			enc.arena = data["arena"]
			enc.experience_reward = data["xp"]
			
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
		"encounters": encounters,
		"chest_state": chest_state
	}
	
	return dungeon_data
	
func from_dict(data: Dictionary) -> void:
	var dungeon: Dictionary = data.duplicate(true)
	player_position = dungeon["player_position"]
	player_facing = dungeon["player_facing"]
	cleared_encounters = dungeon["cleared_encounters"]
	encounters = dungeon["encounters"]
	chest_state = dungeon["chest_state"]
	LoadBus.loaded.emit(dungeon["id"])
