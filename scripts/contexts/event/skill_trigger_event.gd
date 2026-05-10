extends TriggerEvent

class_name SkillTriggerEvent

var skill: Skill = null
var cost: SkillCost = null


func _init(s: Skill, t: CharacterInstance) -> void:
	skill = s
	target = t
	
	if skill.cost:
		cost = skill.cost
	else:
		cost = SkillCost.new()
