extends EffectResolver

class_name HealingResolver


var heal: int = 0


func _init(val: int) -> void:
	heal = val


func execute(ctx: ActionContext) -> ActionContext:
	for target in ctx.targets:
		var event := HealTriggerEvent.new(ctx, target, heal)
		run_pipeline(event)

	return ctx


func run_pipeline(event: HealTriggerEvent) -> void:
	EffectRunner.process_trigger(EffectTriggers.ON_HEAL, event)
	
	EffectRunner.process_trigger(EffectTriggers.ON_RECEIVE_HEAL, event)

	event.target.set_current_health(event.target.state.current_health + event.heal)

	BattleTextLines.print_line("%s healed %s for %d" % [event.actor.get_source_name(), event.target.resource.name, event.heal])
