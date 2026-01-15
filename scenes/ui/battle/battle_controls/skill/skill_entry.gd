extends Button
class_name SkillEntryInterface


func bind(skill: Skill, c: CharacterInstance) -> Skill:
	var cost: SkillCost = skill.compute_cost(c)
	
	var skill_name: String = skill._get_name()
	var skill_cost: String = "%s MP/%s SP" % [cost.get_mana_cost(), cost.get_sp_cost()]
	
	text = "%s %s" % [skill_name, skill_cost]
	disabled = !skill.can_use(c)
	
	return skill
