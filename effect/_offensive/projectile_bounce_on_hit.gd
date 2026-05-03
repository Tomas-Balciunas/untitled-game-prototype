extends PassiveEffect

class_name ProjectileBounceOnHit

@export var bounces: int = 5


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]


func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.OWNER_IS_ACTOR

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event.ctx.actively_cast


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	if !_event is DamageInstance:
		return
	
	var event: DamageInstance = _event as DamageInstance
	
	var resolver: DamageResolver = DamageResolver.new(5)
	var launcher: BounceProjectileLauncher = BounceProjectileLauncher.new(resolver, event.ctx)
	launcher.bounce(bounces)
