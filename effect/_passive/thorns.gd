extends PassiveEffect

class_name ThornsEffect

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_target(event) and !owner_is_actor(event)

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var ctx = ActionContext.new()
	ctx.set_targets(event.source.get_actor())
	ctx.actively_cast = false
	ctx.source = CharacterSource.new(owner)
	
	var resolver = DamageResolver.new(5)
	resolver.execute(ctx)
