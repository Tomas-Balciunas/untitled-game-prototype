extends Node
class_name EnemyController

@export var spawner_scene: PackedScene = preload("uid://c8fyl6fq4crr0")
@export var randomize_spawn := true
@export var min_group_size := 1
@export var max_group_size := 2

func populate_enemy_spawn_points():
	if MapInstance.available_enemies.is_empty():
		push_error("Map instance has no available enemies!")
		
	var points = get_children()
	
	for point in points:
		if not point is Marker3D:
			continue
		
		if point.spawn_id == "":
			push_error("% map doesnt have a spawn id in marker!" % MapInstance.map_id)
			
		var encounter_data
		var saved_encounter = MapInstance.get_encounter(point.spawn_id)
		
		if !saved_encounter:
			encounter_data = build_encounter(point.spawn_id)
		else:
			encounter_data = saved_encounter

		var spawner = spawner_scene.instantiate()
		spawner.encounter_data = encounter_data
		spawner.global_transform = point.global_transform
		spawner.enemy_scene = encounter_data.enemies[0].character_body
		add_child(spawner)

func build_encounter(spawn_id: String) -> EncounterData:
	var data := EncounterData.new()
	data.id = spawn_id
	data.arena = "arena_default_00"

	var pool = MapInstance.available_enemies
	var enemy_count = randi_range(min_group_size, max_group_size)
	data.enemies = []

	#TODO implement an actual experience calculator
	for i in range(enemy_count):
		data.enemies.append(pool.pick_random())
		data.experience_reward += 200

	return data
