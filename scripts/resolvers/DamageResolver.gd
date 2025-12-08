extends EffectResolver

class_name DamageResolver


func execute(_ctx: ActionContext) -> DamageContext:
	var ctx := _ctx as DamageContext
	
	if ctx == null:
		push_error("DamageResolver received invalid context")
		return ctx
	#TODO: refactor trigger flow
	var event := TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	
	event.trigger = EffectTriggers.ON_HIT
	EffectRunner.process_trigger(event)
	
	event.trigger = EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE
	EffectRunner.process_trigger(event)
	
	var defense_ignore := 0
	if ctx.has_meta("ignore_defense_percent"):
		defense_ignore = ctx.get_meta("ignore_defense_percent")
	
	var calculator := DamageCalculator.new(ctx, defense_ignore)
	ctx.final_value = max(calculator.get_final_damage(), 0)
	
	BattleEventBus.before_receive_damage.emit(ctx)
	await BattleFlow.wait_if_paused()
	event.trigger = EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED
	EffectRunner.process_trigger(event)
	
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [ctx.source.get_source_name(), ctx.final_value, DamageTypes.to_str(ctx.type), ctx.target.resource.name])
	event.ctx.target.set_current_health(event.ctx.target.state.current_health - event.ctx.final_value)
	
	
	event.trigger = EffectTriggers.ON_DAMAGE_APPLIED
	EffectRunner.process_trigger(event)
	
	if event.ctx.target.is_dead:
		event.trigger = EffectTriggers.ON_DEATH
		EffectRunner.process_trigger(event)
		return ctx
	
	return ctx
