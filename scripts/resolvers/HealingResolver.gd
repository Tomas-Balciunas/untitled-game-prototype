extends EffectResolver

class_name HealingResolver

func execute(_ctx: ActionContext) -> HealingContext:
	var ctx := _ctx as HealingContext
	
	if ctx == null:
		push_error("HealingResolver received invalid context")
		return ctx
	
	for target in ctx.targets:
		var event := TriggerEvent.new()
		event.actor = ctx.source
		event.target = target
		event.ctx = ctx
		run_pipeline(event)
	

	return ctx


func run_pipeline(event: TriggerEvent) -> void:
	event.trigger = EffectTriggers.ON_HEAL
	EffectRunner.process_trigger(event)
	
	event.trigger = EffectTriggers.ON_RECEIVE_HEAL
	EffectRunner.process_trigger(event)

	event.target.set_current_health(event.target.state.current_health + event.ctx.final_value)

	BattleTextLines.print_line("%s healed %s for %d" % [event.actor.get_source_name(), event.target.resource.name, event.ctx.final_value])
