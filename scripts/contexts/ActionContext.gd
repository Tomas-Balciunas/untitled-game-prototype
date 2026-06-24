class_name ActionContext

var _turn: TurnState = null
var turn: TurnState:
	get:
		return BattleContext.get_turn_state()
	set(value): _turn = value

var source: ContextSource = null
var initial_target: Character = null
var targets: Array[Character] = []
var temporary_effects: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
var stop_processing: bool = false
var root_trigger: Effect = null
var targeting: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
var attack_rate: int = 1

var skip_turn: bool = false
var force_action: bool = false
var forced_skill: Skill = null

var additional_procs: Array = []


func set_targets(initial: Character, all_targets: Array[Character] = []) -> void:
	initial_target = initial
	targets = all_targets
	
	if all_targets.is_empty():
		targets.append(initial_target)
