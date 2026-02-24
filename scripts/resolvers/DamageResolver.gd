extends EffectResolver

class_name DamageResolver

var damage: int = 0


func _init(val: int) -> void:
	damage = val

func execute(ctx: ActionContext) -> ActionContext:
	for target in ctx.targets:
		var event: DamageTriggerEvent = build_event(ctx, target)
		run_pipeline(event)
	
	for i in len(ctx.additional_procs):
		ctx.additional_procs[i]["resolver"].execute(ctx.additional_procs[i]["ctx"])
		ctx.additional_procs.erase(ctx.additional_procs[i])
	
	return ctx


func run_pipeline(event: DamageTriggerEvent) -> void:
	#TODO: refactor trigger flow
	EffectRunner.process_trigger(EffectTriggers.ON_HIT, event)
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE, event)
	
	#BattleEventBus.before_receive_damage.emit(ctx)
	#await BattleFlow.wait_if_paused()
	EffectRunner.process_trigger(EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED, event)
	
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [
		event.ctx.source.get_source_name(), 
		event.calculator.get_final_damage(), 
		DamageTypes.to_str(event.calculator.type), 
		event.target.resource.name
		])
		
	event.target.set_current_health(event.target.state.current_health - event.calculator.get_final_damage())
	
	EffectRunner.process_trigger(EffectTriggers.ON_DAMAGE_APPLIED, event)
	
	## should be in battle state
	#if event.ctx.target.is_dead:
		#event.trigger = EffectTriggers.ON_DEATH
		#EffectRunner.process_trigger(event)
	


func build_event(ctx: ActionContext, target: CharacterInstance) -> DamageTriggerEvent:
	return DamageTriggerEvent.new(ctx, target, damage)
