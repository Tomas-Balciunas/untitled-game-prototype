extends PassiveEffect

class_name MpCostReduction

@export var modifier: float = 0.2

func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.GLOBAL

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false

func listened_triggers() -> Array:
	return []

func _modifies_skill_cost() -> bool:
	return true

func modify_skill_cost(_skill: Skill, sc: SkillCost) -> SkillCost:
	sc.mana = sc.mana - _skill.cost.get_mana_cost() * modifier
	return sc
