extends EffectResolver

class_name EffectApplicationResolver


func execute(_ctx: ActionContext) -> EffectApplicationContext:
	var ctx := _ctx as EffectApplicationContext
	
	if ctx == null:
		push_error("EffectApplicationResolver received invalid context")
		return ctx
	
	for target in ctx.targets:
		var event := TriggerEvent.new()
		event.actor = ctx.source
		event.target = target
		event.ctx = ctx
		
		run_pipeline(event)

	return ctx


func run_pipeline(event: TriggerEvent) -> void:
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_APPLY_EFFECT, event)
	
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_RECEIVE_EFFECT, event)
	
	event.target.apply_effect(event.ctx.effect, event.actor)
	
	EffectRunner.process_trigger(EffectTriggers.ON_APPLY_EFFECT, event)
