extends RefCounted

class_name DungeonState

var map_id: String
var current_map_name: String = ""
var theme: String = ""
var player_position: Vector2i = Vector2i()
var player_previous_position: Vector2i = Vector2i()
var player_facing: Vector3 = Vector3.FORWARD
var encounters := {}
var cleared_encounters: Dictionary = {}
var transitions := {}
var available_enemies: Array[CharacterResource] = []
var available_tiers: Array = []
var chest_state: Dictionary = {}
var seeds: Dictionary = {}

var door_state: Dictionary = {}
var granted_keys: Dictionary = {}
var pending_keys: Dictionary = {}
var expected_keys: Dictionary = {}

var _restored_from_save: bool = false

func hydrate_from_resource(map_data: Dictionary) -> void:
	map_id = map_data.id
	current_map_name = map_data.name
	#TODO: more safety checks
	var start_str: String = map_data.get("starting_position", "(0, 0)")
	player_position = str_to_var("Vector2i" + start_str)
	player_previous_position = player_position
	if not cleared_encounters.has(map_id):
		cleared_encounters[map_id] = []
	hydrate_enemy_pool(map_data)

func hydrate_enemy_pool(map_data: Dictionary) -> void:
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

func consume_restore_flag() -> bool:
	var was := _restored_from_save
	_restored_from_save = false
	return was

func update_player_position(pos: Vector2i, facing: Vector3) -> void:
	player_previous_position = player_position
	player_position = pos
	player_facing = facing

	for c: Character in RunState.current.party.members:
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

	var entries: Array = []

	for enemy: EncounterEnemy in data.enemies:
		if enemy == null or enemy.resource == null:
			continue

		entries.append({
			"id": enemy.resource.id,
			"level": enemy.level,
			"experience_multiplier": enemy.experience_multiplier,
			"name_override": enemy.name_override,
		})

	encounters[map_id][data.id] = {
		"id": data.id,
		"enemies": entries,
		"arena": data.arena,
	}

func get_encounter(id: String) -> EncounterData:
	if not encounters.has(map_id):
		return null

	if not encounters[map_id].has(id):
		return null

	var data: Dictionary = encounters[map_id][id]
	var enemies: Array[EncounterEnemy] = []

	for entry: Dictionary in data.get("enemies", []):
		var character_id: String = entry.get("id", "")
		var resource := CharacterRegistry.get_character(character_id)

		if resource == null:
			SaveManager.report_load_issue("Encounter %s: unknown character resource '%s'" % [id, character_id])
			continue

		var encounter_enemy := EncounterEnemy.new()
		encounter_enemy.resource = resource
		encounter_enemy.level = entry.get("level", 1)
		encounter_enemy.experience_multiplier = entry.get("experience_multiplier", 1.0)
		encounter_enemy.name_override = entry.get("name_override", "")
		enemies.append(encounter_enemy)

	if enemies.is_empty():
		return null

	var enc := EncounterData.new()
	enc.id = data["id"]
	enc.enemies = enemies
	enc.arena = data.get("arena", "arena_default_00")

	return enc

func mark_encounter_cleared(encounter_id: String) -> void:
	cleared_encounters[map_id].append(encounter_id)

func is_encounter_cleared(encounter_id: String) -> bool:
	if not cleared_encounters.has(map_id):
		return false
	return cleared_encounters[map_id].has(encounter_id)

func get_door_state(door_id: String) -> Dictionary:
	return door_state.get(map_id, {}).get(door_id, {})

func set_door_state(door_id: String, payload: Dictionary) -> void:
	if not door_state.has(map_id):
		door_state[map_id] = {}

	door_state[map_id][door_id] = payload

func is_key_granted(key_id: String) -> bool:
	return granted_keys.get(map_id, {}).has(key_id)

func mark_key_granted(key_id: String) -> void:
	if not granted_keys.has(map_id):
		granted_keys[map_id] = {}

	granted_keys[map_id][key_id] = true

func queue_pending_key(entry: Dictionary) -> void:
	if not pending_keys.has(map_id):
		pending_keys[map_id] = []

	pending_keys[map_id].append(entry)

func take_pending_keys() -> Array:
	var owed: Array = pending_keys.get(map_id, [])
	pending_keys[map_id] = []

	return owed

func register_expected_key(key_id: String, info: Dictionary) -> void:
	if not expected_keys.has(map_id):
		expected_keys[map_id] = {}

	expected_keys[map_id][key_id] = info

func get_expected_keys() -> Dictionary:
	return expected_keys.get(map_id, {})

func game_save() -> Dictionary:
	return {
		"id": map_id,
		"name": current_map_name,
		"theme": theme,
		"player_position": player_position,
		"player_previous_position": player_previous_position,
		"player_facing": player_facing,
		"cleared_encounters": cleared_encounters,
		"encounters": encounters,
		"chest_state": chest_state,
		"seeds": seeds,
		"door_state": door_state,
		"granted_keys": granted_keys,
		"pending_keys": pending_keys,
		"expected_keys": expected_keys,
	}

func game_load(data: Dictionary) -> void:
	var dungeon: Dictionary = data.duplicate(true)
	map_id = dungeon.get("id", "")
	current_map_name = dungeon.get("name", "")
	theme = dungeon.get("theme", "")
	player_position = dungeon.get("player_position", Vector2i())
	player_previous_position = dungeon.get("player_previous_position", player_position)
	player_facing = dungeon.get("player_facing", Vector3.FORWARD)
	cleared_encounters = dungeon.get("cleared_encounters", {})
	encounters = dungeon.get("encounters", {})
	chest_state = dungeon.get("chest_state", {})
	seeds = dungeon.get("seeds", {})
	door_state = dungeon.get("door_state", {})
	granted_keys = dungeon.get("granted_keys", {})
	pending_keys = dungeon.get("pending_keys", {})
	expected_keys = dungeon.get("expected_keys", {})
	_restored_from_save = true
	LoadBus.loaded.emit(map_id)
