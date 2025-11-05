extends EffectResolver

class_name DamageResolver


func execute(_ctx: ActionContext) -> DamageContext:
	var ctx := _ctx as DamageContext
	
	if ctx == null:
		push_error("DamageResolver received invalid context")
		return ctx
	
	var event := TriggerEvent.new()
	event.actor = ctx.source
	event.ctx = ctx
	event.trigger = EffectTriggers.ON_HIT
	
	# attacker’s effects
	EffectRunner.process_trigger(event)
	
	# defender’s effects
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
	
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [ctx.source.resource.name, ctx.final_value, DamageTypes.to_str(ctx.type), ctx.target.resource.name])
	event.ctx.target.set_current_health(event.ctx.target.stats.current_health - event.ctx.final_value)
	
	if event.ctx.target.is_dead:
		event.trigger = EffectTriggers.ON_DEATH
		EffectRunner.process_trigger(event)
		return ctx
	
	event.trigger = EffectTriggers.ON_DAMAGE_APPLIED
	EffectRunner.process_trigger(event)
	
	if event.ctx.has_meta("counterattack"):
		var counter_target: CharacterInstance = ctx.get_meta("counterattack")
		var revenge := DamageContext.new()
		revenge.source = event.ctx.target
		revenge.target = counter_target
		revenge.type = ctx.target.damage_type
		revenge.base_value = ctx.target.stats.get_final_stat(Stats.ATTACK)
		revenge.final_value = ctx.target.stats.get_final_stat(Stats.ATTACK)
		revenge.actively_cast = false #important, setting it to false would not trigger counterattack chain
		BattleContext.manager.action_queue.append(revenge)
		BattleTextLines.print_line("%s counterattacks!" % revenge.source.resource.name)
	return ctx
