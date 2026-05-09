extends PassiveEffect

class_name ThornsEffect

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func get_scope() -> EffectScope:
	return Effect.EffectScope.OWNER_IS_TARGET

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var ctx = ActionContext.new()
	ctx.set_targets(event.actor.get_actor())
	ctx.actively_cast = false
	ctx.source = CharacterSource.new(owner)
	
	var resolver = DamageResolver.new(5)
	resolver.execute(ctx)
