extends PassiveEffect

class_name HealOnKill

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DEATH]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_actor(event) and event.target != owner

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	owner.set_current_health(owner.state.current_health + 5)
