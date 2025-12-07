extends PassiveEffect
class_name Heal

@export var heal_amount: int = 20

func listened_triggers() -> Array:
	return [EffectTriggers.ON_USE_CONSUMABLE]
	
func can_process(_event: TriggerEvent) -> bool:
	return true

func on_trigger(event: TriggerEvent) -> void:
	var action := HealingContext.new()
	action.base_value = heal_amount
	action.final_value = heal_amount
	action.source = event.ctx.source
	action.target = event.ctx.target
	
	HealingResolver.new().execute(action)

func get_description() -> String:
	return "Heals for %s" % heal_amount
