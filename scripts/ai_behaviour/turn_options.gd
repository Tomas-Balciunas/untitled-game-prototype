extends RefCounted

class_name TurnOptions

enum AllowedSides {
	DEFAULT,
	BOTH,
	INVERTED
}

var actor: Character = null
var allowed_skill_categories: Array[Skill.SkillCategory] = [
		Skill.SkillCategory.DAMAGE,
		Skill.SkillCategory.HARM,
		Skill.SkillCategory.SUPPORT,
		Skill.SkillCategory.SUSTAIN
	]
var forced_targets: Array = []
var forced_actions: Array = []
var allowed_sides: AllowedSides = AllowedSides.DEFAULT
## CC check basically
var pass_turn: bool = false
## for player - forces an ai to act instead manual choice
var coerce_turn: bool = false

func _init(_actor: Character) -> void:
	actor = _actor
