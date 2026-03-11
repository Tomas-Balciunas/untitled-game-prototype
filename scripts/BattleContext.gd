extends Node

signal actions_concluded

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


func new_action() -> void:
	pending_actions += 1
	print("Pending actions: %s" % pending_actions)


func end_action() -> void:
	pending_actions = max(pending_actions - 1, 0)
	print("Pending actions: %s" % pending_actions)
	
	if pending_actions <= 0:
		actions_concluded.emit()


func get_enemies_all() -> Array[CharacterInstance]:
	return manager.enemies


func get_allies_all() -> Array[CharacterInstance]:
	return manager.party


func get_battlers_all() -> Array[CharacterInstance]:
	return manager.battlers


func get_slots_enemies() -> Array[FormationSlot]:
	return enemy_formation.get_all_slots()


func get_slots_allies() -> Array[FormationSlot]:
	return ally_formation.get_all_slots()
