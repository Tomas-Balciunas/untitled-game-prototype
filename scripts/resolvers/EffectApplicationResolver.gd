extends EffectResolver

class_name EffectApplicationResolver

var effect: Effect = null


func _init(e: Effect) -> void:
	effect = e


func execute(ctx: ActionContext) -> ActionContext:
	if !effect:
		push_error("Effect missing")
		return
	
	for target in ctx.targets:
		if not is_target_valid(target):
			continue
		
		var event := EffectApplicationTriggerEvent.new(ctx, target, effect)
		run_pipeline(event)

	return ctx


func run_pipeline(event: EffectApplicationTriggerEvent) -> void:
	EffectRunner.process_trigger(EffectTriggers.ON_BEFORE_APPLY_EFFECT, event)
	
	event.target.apply_effect(effect, event.source)
	
	if event.source.skill:
		BattleTextLines.print_line("%s cast %s on %s" % [
				event.source.get_source_name(),
				event.source.skill._get_name(),
				event.target.resource.name,
			])
	else:
		BattleTextLines.print_line("%s applied %s on %s" % [
			event.source.get_source_name(),
			effect._get_name(),
			event.target.resource.name,
		])
	
	EffectRunner.process_trigger(EffectTriggers.ON_APPLY_EFFECT, event)
