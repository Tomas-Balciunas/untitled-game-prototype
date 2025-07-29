extends Node

var in_battle: bool = false
var manager: BattleManager = null
var enemy_grid: Node = null

func fill_context(battle_manager: BattleManager, enemy_formation: Node):
	in_battle = true
	manager = battle_manager
	enemy_grid = enemy_formation

func clear_context():
	in_battle = false
	manager = null
	enemy_grid = null
