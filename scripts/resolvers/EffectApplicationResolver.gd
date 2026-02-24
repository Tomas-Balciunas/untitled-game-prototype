extends EffectResolver

class_name EffectApplicationResolver

var effect: Effect = null


func _init(e: Effect) -> void:
	effect = e


func execute(ctx: ActionContext) -> EffectApplicationContext:
	if !effect:
		push_error("Effect missing")
		return
	
	for target in ctx.targets:
		var event := EffectApplicationTriggerEvent.new(ctx, target, effect)
		run_pipeline(event)

	return ctx


func run_pipeline(event: EffectApplicationTriggerEvent) -> void:
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_APPLY_EFFECT, event)
	
	event.target.apply_effect(effect, event.actor)
	
	EffectRunner.process_trigger(EffectTriggers.ON_APPLY_EFFECT, event)
