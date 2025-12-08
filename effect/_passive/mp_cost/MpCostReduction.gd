extends PassiveEffect

class_name MpCostReduction

@export var modifier: float = 0.2

func can_process(_event: TriggerEvent) -> bool:
	return false

func listened_triggers() -> Array:
	return []

func _modifies_skill_cost() -> bool:
	return true

func modify_skill_cost(skill: Skill) -> Skill:
	skill.final_mp_cost = round(skill.final_mp_cost * (1.0 - modifier))
	return skill
