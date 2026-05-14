extends EventStep
class_name EncounterStep

@export var arena: String = "arena_default_00"
@export var enemies: Array[String] = []


func run(_manager: EventManager) -> void:
	var enemy_instances: Array[CharacterResource] = []
	for e in enemies:
		enemy_instances.append(CharacterRegistry.get_character(e))

	var data := EncounterData.new()
	data.id = "event_encounter"
	data.arena = arena
	data.enemies = enemy_instances

	EncounterBus.encounter_started.emit(data)
	await EncounterBus.encounter_ended


static func against(p_arena: String, p_enemies: Array) -> EncounterStep:
	var s := EncounterStep.new()
	s.arena = p_arena
	var typed: Array[String] = []
	for e in p_enemies:
		typed.append(e)
	s.enemies = typed
	return s
