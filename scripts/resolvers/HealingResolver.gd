extends EffectResolver

class_name HealingResolver

func execute(_ctx: ActionContext) -> HealingContext:
	var ctx := _ctx as HealingContext
	
	if ctx == null:
		push_error("HealingResolver received invalid context")
		return ctx
		
	var event := TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	event.trigger = EffectTriggers.ON_HEAL
	
	EffectRunner.process_trigger(event)
	
	event.trigger = EffectTriggers.ON_RECEIVE_HEAL
	EffectRunner.process_trigger(event)

	event.ctx.target.set_current_health(event.ctx.target.stats.current_health + event.ctx.final_value)

	BattleTextLines.print_line("%s healed %s for %d" % [event.actor.resource.name, event.ctx.target.resource.name, ctx.final_value])

	return ctx
