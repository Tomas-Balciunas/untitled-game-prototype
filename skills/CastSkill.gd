extends Skill

class_name CastSkill

@export var effect: Effect

func build_context(skill_context: SkillContext) -> EffectApplicationContext:
	var ctx := EffectApplicationContext.new()
	ctx.effect = effect
	ctx.source = skill_context.source
	ctx.initial_target = skill_context.initial_target
	ctx.targets = skill_context.targets
	ctx.temporary_effects = effects
	
	return ctx

func get_resolver() -> EffectApplicationResolver:
	return EffectApplicationResolver.new()
