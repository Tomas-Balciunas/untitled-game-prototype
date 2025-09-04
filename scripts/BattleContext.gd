extends Node

var in_battle: bool = false
var event_running: bool = false
var manager: BattleManager = null
var enemy_grid: Node = null
var encounter_id: String = ""

func fill_context(battle_manager: BattleManager, enemy_formation: Node, id: String):
	in_battle = true
	manager = battle_manager
	enemy_grid = enemy_formation
	encounter_id = id

func clear_context():
	in_battle = false
	manager = null
	enemy_grid = null
	encounter_id = ""
