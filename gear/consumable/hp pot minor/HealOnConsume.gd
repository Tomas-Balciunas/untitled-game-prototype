extends PassiveEffect
class_name Heal

@export var heal_amount: int = 20

func listened_triggers() -> Array:
	return [EffectTriggers.ON_USE_CONSUMABLE]
	
func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var action := ActionContext.new()
	action.source = event.actor
	action.set_targets(event.target)
	
	HealingResolver.new(heal_amount).execute(action)

func get_description() -> String:
	return "Heals for %s" % heal_amount
