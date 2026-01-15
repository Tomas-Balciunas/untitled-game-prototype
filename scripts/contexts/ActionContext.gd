
class_name ActionContext

var source: ContextSource
var initial_target: CharacterInstance
var targets: Array[CharacterInstance]
var temporary_effects: Array[Effect] = []
var options: Dictionary = {}
var actively_cast: bool = false
var stop_processing: bool = false
var root_trigger: Effect = null

var skip_turn: bool = false
var force_action: bool = false
var forced_skill: Skill = null
