extends Node

var in_battle: bool = false
var event_running: bool = false
var manager: BattleManager = null
var enemy_grid: Node = null
var encounter_data: EncounterData = null

func fill_context(battle_manager: BattleManager, enemy_formation: Node, data: EncounterData):
	in_battle = true
	manager = battle_manager
	enemy_grid = enemy_formation
	encounter_data = data

func clear_context():
	in_battle = false
	manager = null
	enemy_grid = null
	encounter_data = null
