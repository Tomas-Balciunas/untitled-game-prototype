extends Node
class_name EnemyController

@export var spawner_scene: PackedScene = preload("uid://c8fyl6fq4crr0")
@export var randomize_spawn := true
@export var min_group_size := 4
@export var max_group_size := 7


func populate_enemy_spawn_points() -> void:
	if MapInstance.available_enemies.is_empty():
		push_error("Map instance has no available enemies!")
		return

	var points := get_children()
	
	for point in points:
		if not point is Marker3D:
			continue
		
		var lvl_range: Array = []
		
		if !point.level_range:
			var avg_lvl: int = PartyManager.get_average_party_level()
			lvl_range = [max(1, avg_lvl - 1), avg_lvl + 1]
		else:
			lvl_range = point.level_range
		
		if point.spawn_id == "":
			push_error("% map doesnt have a spawn id in marker!" % MapInstance.map_id)
			
		var encounter_data: EncounterData
		var saved_encounter := MapInstance.get_encounter(point.spawn_id)
		
		if !saved_encounter:
			encounter_data = build_encounter(point.spawn_id, lvl_range, point.reward_keys)
		else:
			encounter_data = saved_encounter

		if encounter_data.enemies.is_empty():
			push_error("EnemyController: no enemies built for spawn %s" % point.spawn_id)
			continue

		var spawner := spawner_scene.instantiate()
		spawner.encounter_data = encounter_data
		spawner.global_transform = point.global_transform
		spawner.enemy_scene = encounter_data.enemies[0].resource.character_body
		add_child(spawner)

func build_encounter(spawn_id: String, level_range: Array, reward_keys: Array = []) -> EncounterData:
	assert(level_range[0] is int)
	assert(level_range[1] is int)
	assert(level_range[0] <= level_range[1])
	
	var data := EncounterData.new()
	data.id = spawn_id
	data.arena = "arena_default_00"
	data.enemies = []
	
	for entry: Dictionary in reward_keys:
		var key_id: String = entry.get("id", "")
		if key_id.is_empty() or MapInstance.is_key_granted(key_id):
			continue
		data.item_rewards.append(KeyFactory.rebuild(key_id, entry.get("name", "Key")))

	var pool := MapInstance.available_enemies
	var enemy_count := randi_range(min_group_size, max_group_size)

	for i in range(enemy_count):
		var encounter_enemy: EncounterEnemy = EncounterEnemy.new()
		encounter_enemy.level = range(level_range[0], level_range[1] + 1).pick_random()
		encounter_enemy.resource = pool.pick_random()
		data.enemies.append(encounter_enemy)

	return data
