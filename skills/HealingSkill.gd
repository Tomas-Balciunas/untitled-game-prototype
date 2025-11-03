extends Skill

class_name HealingSkill

@export var healing_amount: int = 0

func build_context(_source: CharacterInstance, _target: CharacterInstance) -> HealingContext:
	var ctx := HealingContext.new()
	ctx.base_value = healing_amount
	ctx.final_value = healing_amount
	ctx.source = _source
	ctx.target = _target
	ctx.temporary_effects = effects
	
	return ctx

func get_resolver() -> HealingResolver:
	return HealingResolver.new()
