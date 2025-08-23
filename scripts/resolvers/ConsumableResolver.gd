extends Node

func apply_consumable(action: ConsumableAction):
	var ctx = ConsumableContext.new()
	ctx.source = action.source
	ctx.target = action.target
	ctx.consumable = action.consumable
	ctx.actively_cast = action.actively_cast

	for trig in [
		EffectTriggers.ON_BEFORE_USE_CONSUMABLE,
		EffectTriggers.ON_USE_CONSUMABLE,
		EffectTriggers.ON_POST_USE_CONSUMABLE
	]:
		var ev = TriggerEvent.new()
		ev.actor = ctx.source
		ev.ctx = ctx
		ev.tags = ctx.consumable.get_all_effects()
		ev.trigger = trig
		EffectRunner.process_trigger(ev)
