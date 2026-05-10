extends PassiveEffect
class_name StunOnHitEffect

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event.ctx.actively_cast and owner_is_actor(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var stun := StunEffect.new()
	stun.duration_turns = 1
	
	var act := EffectApplicationContext.new()
	act.actively_cast = event.ctx.actively_cast
	act.source = event.source
	act.set_targets(event.target)
	
	EffectApplicationResolver.new(stun).execute(act)
