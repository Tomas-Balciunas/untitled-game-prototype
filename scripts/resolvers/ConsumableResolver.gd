extends EffectResolver

class_name ConsumableResolver

var consumable: Consumable = null

func _init(c: Consumable) -> void:
	consumable = c


func execute(ctx: ActionContext) -> ActionContext:
	for target in ctx.targets:
		var event: ConsumableTriggerEvent = ConsumableTriggerEvent.new(ctx, target, consumable)
		run_pipeline(event)
	
	return ctx


func run_pipeline(event: ConsumableTriggerEvent) -> void:
	for trig: String in [
		EffectTriggers.ON_BEFORE_USE_CONSUMABLE,
		EffectTriggers.ON_USE_CONSUMABLE,
		EffectTriggers.ON_POST_USE_CONSUMABLE
	]:
		EffectRunner.process_trigger(trig, event)
