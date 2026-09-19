extends BuffEffect

class_name Revive

func listened_triggers() -> Array:
	return [EffectTriggers.ON_APPLY_EFFECT]

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return owner_is_target(_event)

func on_trigger(_stage: String, _ctx: TriggerEvent) -> void:
	owner.revive(200)

func can_process_when_owner_dead() -> bool:
	return true
