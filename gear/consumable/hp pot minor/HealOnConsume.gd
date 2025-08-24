extends Effect
class_name Heal

@export var heal_amount: int = 20

func listened_triggers() -> Array:
	return [EffectTriggers.ON_USE_CONSUMABLE]
	
func can_process(event: TriggerEvent) -> bool:
	return true

func on_trigger(event: TriggerEvent) -> void:
	var action = HealingAction.new()
	action.base_value = heal_amount
	action.provider = event.ctx.source
	action.receiver = event.ctx.target
	
	HealingResolver.apply_heal(action)

func get_description() -> String:
	return "Heals for %s" % heal_amount
