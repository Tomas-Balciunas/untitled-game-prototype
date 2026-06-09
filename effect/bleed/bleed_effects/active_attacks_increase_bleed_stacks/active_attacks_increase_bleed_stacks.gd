extends PassiveEffect

class_name ActiveAttacksIncreaseBleedStacks

@export var stack_increase: float = 0.05

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	if !event.ctx.actively_cast:
		return false
	
	if !event.source.get_actor() == owner:
		return false
		
	
	return event.target != null and Bleed.is_affected_by_bleed(event.target)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	for effect: Effect in event.target.effects:
		if effect is Bleed:
			var bleed: Bleed = effect as Bleed
			bleed.stacks = roundi(bleed.stacks * (1 + stack_increase))
