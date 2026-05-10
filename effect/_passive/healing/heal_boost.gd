extends PassiveEffect

class_name HealBoost

@export var modifier: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HEAL]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_actor(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	event.heal += event.heal * modifier
