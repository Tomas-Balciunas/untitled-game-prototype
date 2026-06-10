extends BuffEffect

class_name PreventDurationLoss


func _init() -> void:
	super()

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DURATION_CONSUME]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	if event is not DurationConsumeEvent:
		return false

	var dce: DurationConsumeEvent = event as DurationConsumeEvent
	
	if !dce.effect:
		return false
	
	if !dce.effect.get_category() == EffectCategory.BUFF:
		return false
	
	return dce.effect != self and dce.effect.owner == owner


func on_trigger(_stage: String, event: TriggerEvent) -> void:
	(event as DurationConsumeEvent).amount = 0


func _get_name() -> String:
	return "Temporal Lock"


func get_description() -> String:
	return "Your buff durations don't decrease until your next turn"
