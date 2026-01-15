extends EffectResolver

class_name DamageResolver


func execute(_ctx: ActionContext) -> DamageContext:
	var ctx := _ctx as DamageContext
	
	if ctx == null:
		push_error("DamageResolver received invalid context")
		return ctx
	#TODO: refactor trigger flow
	
	for target: CharacterInstance in ctx.targets:
		var event := DamageTriggerEvent.new(ctx, target)
		
		run_pipeline(event)
	
	return ctx


func run_pipeline(event: DamageTriggerEvent) -> void:
	event.trigger = EffectTriggers.ON_HIT
	EffectRunner.process_trigger(event)
	
	event.trigger = EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE
	EffectRunner.process_trigger(event)
	
	#BattleEventBus.before_receive_damage.emit(ctx)
	#await BattleFlow.wait_if_paused()
	event.trigger = EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED
	EffectRunner.process_trigger(event)
	
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [event.ctx.source.get_source_name(), event.calculator.get_final_damage(), DamageTypes.to_str(event.ctx.type), event.target.resource.name])
	event.target.set_current_health(event.target.state.current_health - event.calculator.get_final_damage())
	
	
	event.trigger = EffectTriggers.ON_DAMAGE_APPLIED
	EffectRunner.process_trigger(event)
	
	## should be in battle state
	#if event.ctx.target.is_dead:
		#event.trigger = EffectTriggers.ON_DEATH
		#EffectRunner.process_trigger(event)
