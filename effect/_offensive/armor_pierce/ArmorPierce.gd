extends PassiveEffect
class_name ArmorPierce

@export var ignore_percent: float = 0.5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HIT]

func can_process(_event: TriggerEvent) -> bool:
	return false

func on_trigger(event: TriggerEvent) -> void:
	event.ctx.set_meta("ignore_defense_percent", ignore_percent)
