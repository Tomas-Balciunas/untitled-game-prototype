extends Effect

class_name StunOnHitEffect

func listened_triggers() -> Array:
	return [EffectTriggers.ON_HIT]
	
func can_process(event: TriggerEvent) -> bool:
	return event.actor == owner and event.ctx.actively_cast

func on_trigger(event: TriggerEvent) -> void:
	var stun := StunEffect.new()
	stun.duration_turns = 1
	
	var act := EffectApplicationAction.new()
	act.actively_cast = true
	act.source = event.actor
	act.target = event.ctx.target
	act.effect = stun
	
	EffectApplicationResolver.apply_effect(act)
