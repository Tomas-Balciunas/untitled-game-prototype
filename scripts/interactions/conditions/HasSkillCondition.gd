extends InteractionCondition

class_name HasSkillCondition


@export var skill_id: String = ""
@export var target_member_id: String = ""


func matches(_c: BaseCharacterResource) -> bool:
	if skill_id == "":
		push_error("HasSkillCondition has empty skill_id")
		return false

	if target_member_id != "":
		for m: Character in PartyManager.members:
			if m.resource.id == target_member_id:
				return _member_knows(m)
		return false

	for m: Character in PartyManager.members:
		if _member_knows(m):
			return true

	return false


func _member_knows(m: Character) -> bool:
	for s: Skill in m.learnt_skills:
		if s.id == skill_id:
			return true
	return false


static func any_knows(p_skill_id: String) -> HasSkillCondition:
	var c := HasSkillCondition.new()
	c.skill_id = p_skill_id
	return c


static func member_knows(p_member_id: String, p_skill_id: String) -> HasSkillCondition:
	var c := HasSkillCondition.new()
	c.skill_id = p_skill_id
	c.target_member_id = p_member_id
	return c
