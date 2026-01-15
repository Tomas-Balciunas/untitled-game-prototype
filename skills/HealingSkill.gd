extends Skill

class_name HealingSkill

@export var healing_amount: int = 0

func build_context(skill_context: SkillContext) -> HealingContext:
	var ctx := HealingContext.new()
	ctx.base_value = healing_amount
	ctx.final_value = healing_amount
	ctx.source = skill_context.source
	ctx.initial_target = skill_context.initial_target
	ctx.targets = skill_context.targets
	ctx.temporary_effects = effects
	
	return ctx

func get_resolver() -> HealingResolver:
	return HealingResolver.new()
