extends Skill

class_name CastSkill

@export var effect: Effect

func build_context(_source: SkillSource, _target: CharacterInstance) -> EffectApplicationContext:
	var ctx := EffectApplicationContext.new()
	ctx.effect = effect
	ctx.source = _source
	ctx.target = _target
	ctx.temporary_effects = effects
	
	return ctx

func get_resolver() -> EffectApplicationResolver:
	return EffectApplicationResolver.new()
