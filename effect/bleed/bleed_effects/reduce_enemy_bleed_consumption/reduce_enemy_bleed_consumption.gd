extends PassiveEffect

class_name ReduceEnemyBleedConsumption

@export var reduction_amount: float = 0.05

func listened_triggers() -> Array:
	return [Bleed.ON_BLEED_CONSUME]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return !TargetingManager.same_side(owner, event.source.get_actor())

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	if !event is BleedEvent:
		push_error("ReduceEnemyBleedConsumption received incorrect event: %s" % self.get_class())
		
		return
	
	var parsed: BleedEvent = event as BleedEvent
	var after_reduction: float = parsed.stack_loss + reduction_amount
	
	parsed.stack_loss = clampf(0.0, after_reduction, 1.0) 
