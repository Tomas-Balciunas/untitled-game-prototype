extends Node

var in_battle: bool = false
var event_running: bool = false
var pending_actions: int = 0

var manager: BattleManager = null
var enemy_formation: EnemyFormation = null
var ally_formation: AllyFormation = null
var encounter_data: EncounterData = null

var ally_targeting_enabled: bool = false
var enemy_targeting_enabled := false


func fill_context(battle_manager: BattleManager, enemies: EnemyFormation, allies: AllyFormation, data: EncounterData) -> void:
	in_battle = true
	manager = battle_manager
	enemy_formation = enemies
	ally_formation = allies
	encounter_data = data


func clear_context() -> void:
	in_battle = false
	manager = null
	enemy_formation = null
	ally_formation = null
	encounter_data = null


func new_action(event: ActionEvent) -> void:
	if in_battle and manager:
		manager.action_queue.append(event)


func get_enemies_all() -> Array[CharacterInstance]:
	if !manager:
		push_error("Trying to get all enemies on null manager")
		return []
	
	return manager.enemies


func get_allies_all() -> Array[CharacterInstance]:
	if !manager:
		push_error("Trying to get all allies on null manager")
		return []
	
	return manager.party


func get_battlers_all() -> Array[CharacterInstance]:
	if !manager:
		push_error("Trying to get all battlers on null manager")
		return []
	
	return manager.battlers


func get_slots_enemies() -> Array[FormationSlot]:
	if !enemy_formation:
		push_error("Trying to get all enemy slots on null formation")
		return []
	
	return enemy_formation.get_all_slots()


func get_slots_allies() -> Array[FormationSlot]:
	if !ally_formation:
		push_error("Trying to get all ally slots on null formation")
		return []
	
	return ally_formation.get_all_slots()


func get_valid_slots(is_ally: bool) -> Array[FormationSlot]:
	var all: Array[FormationSlot]
	
	if is_ally:
		all = get_slots_allies()
	else:
		all = get_slots_enemies()
	
	var slots: Array[FormationSlot] = []
	
	for slot in all:
		if !slot or !slot.is_slot_targeting_enabled:
			continue
		
		slots.append(slot)
	
	return slots
	
	
func get_slot(character: CharacterInstance, is_ally: bool) -> FormationSlot:
	if !ally_formation or !enemy_formation:
		push_error("Trying to get slot on null formations")
		return null
	
	if is_ally:
		return ally_formation.get_slot_for(character)
	
	return enemy_formation.get_slot_for(character)
	
