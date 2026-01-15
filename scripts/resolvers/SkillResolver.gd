extends EffectResolver

class_name SkillResolver

func execute(_ctx: ActionContext) -> SkillContext:
	var ctx := _ctx as SkillContext
	if ctx == null:
		push_error("SkillResolver received invalid context")
		return ctx
	
	var event := TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	
	event.trigger = EffectTriggers.ON_BEFORE_SKILL_USE
	EffectRunner.process_trigger(event)
	
	var entity_ctx := ctx.skill.build_context(ctx)
	var resolver := ctx.skill.get_resolver()
	
	if !entity_ctx or !resolver:
		push_error("entity ctx or entity resolver missing in skill resolver")
		return ctx
	
	ctx.cost.consume(ctx.source)
	
	resolver.execute(entity_ctx)
	
	event.trigger = EffectTriggers.ON_POST_SKILL_USE
	EffectRunner.process_trigger(event)
	
	return ctx
