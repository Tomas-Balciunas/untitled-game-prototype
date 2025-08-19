extends Effect
class_name Heal

@export var amount: int = 20

func listened_triggers() -> Array:
	return [EffectTriggers.ON_USE_CONSUMABLE]

func on_trigger(event: TriggerEvent) -> void:
	var action = HealingAction.new()
	action.base_value = amount
	action.provider = event.ctx.source
	action.receiver = event.ctx.target
	
	HealingResolver.apply_heal(action)
