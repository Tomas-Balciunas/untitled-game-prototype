extends Node
class_name HealingManager

signal healing_resolved(ctx: HealingContext)

func apply_heal(action: HealingAction) -> HealingContext:
	return _apply_core(
		action.provider,
		action.receiver,
		action.base_value,
		action.options,
	)

func _apply_core(source: CharacterInstance, target: CharacterInstance, base: float, options: Dictionary = {}) -> HealingContext:
	var ctx = HealingContext.new()
	ctx.source    = source
	ctx.target    = target
	ctx.base_value  = base
	ctx.final_value = base
	ctx.options = options
	
	var event = TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	event.trigger = EffectTriggers.ON_HEAL
	
	EffectRunner.process_trigger(event)
	
	event.trigger = EffectTriggers.ON_RECEIVE_HEAL
	EffectRunner.process_trigger(event)

	target.set_current_health(target.stats.current_health + ctx.final_value)

	BattleTextLines.print_line("%s healed %s for %d" % [ctx.source.resource.name, ctx.target.resource.name, ctx.final_value])
	emit_signal("healing_resolved", ctx)

	return ctx
