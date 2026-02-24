extends Skill

class_name CastSkill

@export var effect: Effect


func get_resolver(_ctx: ActionContext) -> EffectApplicationResolver:
	return EffectApplicationResolver.new(effect)
