class_name ActionContext

var _turn: TurnState = null
var turn: TurnState:
	get:
		return RunState.current.battle.get_turn_state()
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

## Per-action instances; copying keeps owner/source off the item/skill templates.
func set_temporary_effects(arr: Array[Effect]) -> void:
	temporary_effects = []

	for e: Effect in arr:
		temporary_effects.append(e.duplicate(true))

func duplicate() -> ActionContext:
	var copy := ActionContext.new()

	copy._turn = _turn
	copy.source = source
	copy.initial_target = initial_target
	copy.targets = targets.duplicate()
	copy.temporary_effects = temporary_effects.duplicate()
	copy.options = options.duplicate()
	copy.actively_cast = actively_cast
	copy.stop_processing = stop_processing
	copy.root_trigger = root_trigger
	copy.targeting = targeting
	copy.attack_rate = attack_rate
	copy.skip_turn = skip_turn
	copy.force_action = force_action
	copy.forced_skill = forced_skill
	copy.additional_procs = additional_procs.duplicate()

	return copy
