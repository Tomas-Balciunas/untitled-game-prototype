extends PassiveEffect

class_name HealBoost

@export var modifier: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HEAL]
	
func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.OWNER_IS_ACTOR

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event is HealTriggerEvent

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	event.heal += event.heal * modifier
