class_name ActionContext

var source: ContextSource
var initial_target: CharacterInstance = null
var targets: Array[CharacterInstance] = []
var temporary_effects: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
var stop_processing: bool = false
var root_trigger: Effect = null

var skip_turn: bool = false
var force_action: bool = false
var forced_skill: Skill = null
var should_tick: bool = false

var additional_procs: Array = []


func set_targets(initial: CharacterInstance, all_targets: Array[CharacterInstance] = []) -> void:
	initial_target = initial
	targets = all_targets
	
	if all_targets.is_empty():
		targets.append(initial_target)
