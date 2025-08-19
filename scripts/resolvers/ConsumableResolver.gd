extends Node

func apply_consumable(action: ConsumableAction):
	var ctx = ConsumableContext.new()
	ctx.source = action.source
	ctx.target = action.target
	ctx.consumable = action.consumable

	for trig in [
		EffectTriggers.ON_BEFORE_USE_CONSUMABLE,
		EffectTriggers.ON_USE_CONSUMABLE,
		EffectTriggers.ON_POST_USE_CONSUMABLE
	]:
		var ev = TriggerEvent.new()
		ev.actor = ctx.source
		ev.ctx = ctx
		ev.tags = ctx.consumable.effects
		ev.trigger = trig
		EffectRunner.process_trigger(ev)
