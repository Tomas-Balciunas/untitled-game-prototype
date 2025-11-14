extends EffectResolver

class_name EffectApplicationResolver


func execute(_ctx: ActionContext) -> EffectApplicationContext:
	var ctx := _ctx as EffectApplicationContext
	
	if ctx == null:
		push_error("EffectApplicationResolver received invalid context")
		return ctx
	
	var event := TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	event.trigger = EffectTriggers.ON_BEFORE_APPLY_EFFECT
	
	EffectRunner.process_trigger(event)
	
	event.trigger = EffectTriggers.ON_BEFORE_RECEIVE_EFFECT
	EffectRunner.process_trigger(event)
	
	ctx.target.apply_effect(ctx.effect, event.actor)
	
	event.trigger = EffectTriggers.ON_APPLY_EFFECT
	EffectRunner.process_trigger(event)

	return ctx
