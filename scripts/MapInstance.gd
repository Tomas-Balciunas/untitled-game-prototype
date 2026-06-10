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
var seeds: Dictionary = {}

func hydrate_from_resource(map_data: Dictionary) -> void:
	map_id = map_data.id
	current_map_name = map_data.name
	#TODO: more safety checks
	var start_str: String = map_data.get("starting_position", "(0, 0)")
	player_position = str_to_var("Vector2i" + start_str)
	player_previous_position = player_position
	cleared_encounters[map_id] = []
	available_enemies = CharacterRegistry.get_characters(map_data.available_enemies)
	available_tiers = map_data.gear_tiers

func get_or_create_seed(id: String) -> int:
	if not seeds.has(id):
		seeds[id] = randi() + 1
	return seeds[id]

func set_player_spawn(pos: Vector2i, facing: Vector3 = Vector3.FORWARD) -> void:
	player_position = pos
	player_previous_position = pos
	player_facing = facing
	
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

	for c: Character in PartyManager.members:
		var ctx := ActionContext.new()
		ctx.source = CharacterSource.new(c)

		var event: TriggerEvent = TriggerEvent.new()
		event.source = ctx.source
		event.ctx = ctx
		# DoTs (poison) subscribe to ON_MOVEMENT and resolve themselves per step.
		EffectRunner.process_trigger(EffectTriggers.ON_MOVEMENT, event)
		
func add_encounter(data: EncounterData) -> void:
	if not encounters.has(map_id):
		encounters[map_id] = {}

	if encounters[map_id].has(data.id):
		return
	
	encounters[map_id][data.id] = {
		"id": data.id,
		"enemies": data.enemies.map(func(e: CharacterResource) -> String: return e.id),
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

func game_save() -> Dictionary:
	return {
		"id": map_id,
		"name": current_map_name,
		"theme": theme,
		"player_position": player_position,
		"player_previous_position": player_previous_position,
		"player_facing": player_facing,
		"triggered_events": triggered_events,
		"cleared_encounters": cleared_encounters,
		"encounters": encounters,
		"chest_state": chest_state,
		"seeds": seeds,
	}

func game_load(data: Dictionary) -> void:
	var dungeon: Dictionary = data.duplicate(true)
	map_id = dungeon.get("id", "")
	current_map_name = dungeon.get("name", "")
	theme = dungeon.get("theme", "")
	player_position = dungeon["player_position"]
	player_previous_position = dungeon.get("player_previous_position", player_position)
	player_facing = dungeon["player_facing"]
	triggered_events = dungeon.get("triggered_events", {})
	cleared_encounters = dungeon["cleared_encounters"]
	encounters = dungeon["encounters"]
	chest_state = dungeon["chest_state"]
	seeds = dungeon.get("seeds", {})
	LoadBus.loaded.emit(map_id)
