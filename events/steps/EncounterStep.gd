extends EventStep
class_name EncounterStep

var arena: String
var enemies: Array

func _init(data: Dictionary):
	arena = data.get("arena", "arena_default_00")
	enemies = data.get("enemies", [])

func run(_manager: Node) -> void:
	var enemy_instances: Array[CharacterResource] = []
	for e in enemies:
		enemy_instances.append(CharacterRegistry.get_character(e))
	
	var data = EncounterData.new()
	data.id = "event_encounter"
	data.arena = arena
	data.enemies = enemy_instances
	
	EncounterManager.start_encounter(data)
	await EncounterManager.encounter_ended
