extends Effect
class_name PoisonRes

@export var resistance: float = 0.2

func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]

func on_trigger(event: TriggerEvent) -> void:
	if not event.ctx.type == DamageTypes.Type.POISON:
		return
	event.ctx.final_value -= (event.ctx.final_value * resistance)
	print("Reducing poison damage for %s to %f" % [event.ctx.target.resource.name, event.ctx.final_value])
