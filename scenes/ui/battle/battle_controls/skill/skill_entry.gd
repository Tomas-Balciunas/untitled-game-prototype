extends Button
class_name SkillEntryInterface


func bind(skill: Skill, c: CharacterInstance) -> Skill:
	var s: Skill = skill.duplicate(true)
	s.set_cost(c)
	
	var skill_name: String = s._get_name()
	var skill_cost: String = "%s MP/%s SP" % [s.final_mp_cost, s.final_sp_cost]
	
	text = "%s %s" % [skill_name, skill_cost]
	disabled = !s.can_use(c)
	
	return s
