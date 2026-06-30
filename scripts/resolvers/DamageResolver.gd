extends EffectResolver

class_name DamageResolver

var damage: int = 0


func _init(val: int) -> void:
	damage = val

func execute(ctx: ActionContext) -> ActionContext:
	for target in ctx.targets:
		if not is_target_valid(target):
			continue
		
		var event: DamageInstance = build_event(ctx, target)
		run_pipeline(event)
	
	for i in len(ctx.additional_procs):
		ctx.additional_procs[i]["resolver"].execute(ctx.additional_procs[i]["ctx"])
		
	ctx.additional_procs = []
	return ctx


func run_pipeline(event: DamageInstance) -> void:
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE, event)
	
	event.calculator.calculate_final_damage()
	
	EffectRunner.process_trigger(EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED, event)
	
	BattleTextLines.print_line("%s dealt %f %s damage to %s" % [
		event.ctx.source.get_source_name(), 
		event.calculator.get_final_damage(), 
		DamageTypes.to_str(event.calculator.type), 
		event.target.resource.name
		])
	
	if event.ctx.turn:
		event.ctx.turn.damage_dealt += event.calculator.get_final_damage()
		event.ctx.turn.damage_instance_count += 1
		if event.ctx.actively_cast:
			event.ctx.turn.active_attack_count += 1
	
	event.target.set_current_health(event.target.state.current_health - event.calculator.get_final_damage(), event, false)
	
	if event.target.is_dead:
		EffectRunner.process_trigger(EffectTriggers.ON_DEATH, event)
		
		if event.target.is_dead:
			event.target.died.emit(event.target)
	
	EffectRunner.process_trigger(EffectTriggers.ON_DAMAGE_APPLIED, event)

func build_event(ctx: ActionContext, target: Character) -> DamageInstance:
	return DamageInstance.new(ctx, target, damage)
