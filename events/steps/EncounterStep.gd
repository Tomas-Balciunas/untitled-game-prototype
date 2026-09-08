extends EventStep
class_name EncounterStep

@export var arena: String = "arena_default_00"
@export var enemies: Array[String] = []


func run(manager: EventManager) -> void:
	var enemy_instances: Array[CharacterResource] = []
	for e in enemies:
		enemy_instances.append(CharacterRegistry.get_character(e))

	var data := EncounterData.new()
	data.id = "event_encounter"
	data.arena = arena
	data.enemies = []
	data.gold_reward = 20

	for res: CharacterResource in enemy_instances:
		var encounter_enemy: EncounterEnemy = EncounterEnemy.new()
		encounter_enemy.resource = res
		data.enemies.append(encounter_enemy)

	manager.run_tree()
	EncounterBus.encounter_started.emit(data)
	await EncounterBus.encounter_ended
	GameState.set_event()
	manager.pause_tree()
