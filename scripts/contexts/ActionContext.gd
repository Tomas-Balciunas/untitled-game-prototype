class_name ActionContext

var source: ContextSource
var initial_target: Character = null
var targets: Array[Character] = []
var temporary_effects: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
var stop_processing: bool = false
var root_trigger: Effect = null
var targeting: TargetingManager.TargetType = TargetingManager.TargetType.SINGLE
var targeting_range: TargetingManager.RangeType = TargetingManager.RangeType.MELEE
var attack_rate: int = 1

var skip_turn: bool = false
var force_action: bool = false
var forced_skill: Skill = null
var should_tick_consume_duration: bool = true
var tick_power: float = 1.0

var additional_procs: Array = []


func set_targets(initial: Character, all_targets: Array[Character] = []) -> void:
	initial_target = initial
	targets = all_targets
	
	if all_targets.is_empty():
		targets.append(initial_target)
