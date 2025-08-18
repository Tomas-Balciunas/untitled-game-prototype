extends Node

signal healing_resolved(ctx: HealingContext)

func apply_effect(action: EffectApplicationAction) -> EffectApplicationContext:
	return _apply_core(
		action.source,
		action.target,
		action.effect,
		action.callable
	)

func _apply_core(source: CharacterInstance, target: CharacterInstance, effect: Effect, callable) -> EffectApplicationContext:
	var ctx = EffectApplicationContext.new()
	ctx.source    = source
	ctx.target    = target
	ctx.effect  = effect
	ctx.callable = callable
	
	var event = TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	event.trigger = EffectTriggers.ON_BEFORE_APPLY_EFFECT
	
	EffectRunner.process_trigger(event)
	
	event.actor = ctx.target
	event.trigger = EffectTriggers.ON_BEFORE_RECEIVE_EFFECT
	EffectRunner.process_trigger(event)
	ctx.target.apply_effect(ctx.effect, ctx)
	event.trigger = EffectTriggers.ON_APPLY_EFFECT
	EffectRunner.process_trigger(event)

	return ctx
