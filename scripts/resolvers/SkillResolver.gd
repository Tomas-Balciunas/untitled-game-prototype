extends EffectResolver

class_name SkillResolver

var skill: Skill = null


func _init(s: Skill) -> void:
	skill = s


func execute(ctx: ActionContext) -> ActionContext:
	var event := SkillTriggerEvent.new(skill)
	event.actor = ctx.source
	event.ctx = ctx
	
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_SKILL_USE, event)
	
	var resolver: EffectResolver = event.skill.get_resolver(ctx)
	
	if !resolver:
		push_error("resolver missing in skill resolver")
		return ctx
	
	event.cost.consume(event.actor)
	
	resolver.execute(ctx)
	
	EffectRunner.process_trigger(EffectTriggers.ON_POST_SKILL_USE, event)
	
	return ctx
