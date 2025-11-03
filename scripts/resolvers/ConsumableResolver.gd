extends EffectResolver

class_name ConsumableResolver

func execute(_ctx: ActionContext) -> ConsumableContext:
	var ctx := _ctx as ConsumableContext
	
	if ctx == null:
		push_error("ConsumableResolver received invalid context")
		return ctx
	
	for trig: String in [
		EffectTriggers.ON_BEFORE_USE_CONSUMABLE,
		EffectTriggers.ON_USE_CONSUMABLE,
		EffectTriggers.ON_POST_USE_CONSUMABLE
	]:
		var ev := TriggerEvent.new()
		ev.actor = ctx.source
		ev.ctx = ctx
		ev.trigger = trig
		EffectRunner.process_trigger(ev)

	return ctx
