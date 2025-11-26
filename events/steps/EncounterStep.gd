extends EventStep
class_name EncounterStep

var arena: String
var enemies: Array

func _init(data: Dictionary) -> void:
	arena = data.get("arena", "arena_default_00")
	enemies = data.get("enemies", [])

func run(_manager: EventManager) -> void:
	var enemy_instances: Array[CharacterResource] = []
	for e: String in enemies:
		enemy_instances.append(CharacterRegistry.get_character(e))
	
	var data := EncounterData.new()
	data.id = "event_encounter"
	data.arena = arena
	data.enemies = enemy_instances
	
	EncounterBus.encounter_started.emit(data)
	_manager.party_panel.enable_party_ui()
	await EncounterBus.encounter_ended
