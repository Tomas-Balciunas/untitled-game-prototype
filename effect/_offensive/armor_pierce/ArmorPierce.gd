extends PassiveEffect
class_name ArmorPierce

@export var ignore_percent: float = 0.5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HIT]

func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.OWNER_IS_ACTOR

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return false

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	event.ctx.set_meta("ignore_defense_percent", ignore_percent)
