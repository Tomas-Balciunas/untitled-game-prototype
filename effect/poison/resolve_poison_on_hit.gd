extends PassiveEffect

class_name ResolvePoisonOnHit

@export var tick_power: float = 0.5

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_actor(event) and event.ctx.actively_cast

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	if event is not DamageInstance:
		return

	var target: Character = (event as DamageInstance).target
	
	if target == null:
		return

	for e: Effect in target.effects:
		if e is PoisonEffect:
			(e as PoisonEffect).trigger(tick_power)
