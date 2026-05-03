extends PassiveEffect

class_name PoisonOnTurnStart

func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START]
	
func get_scope() -> Effect.EffectScope:
	return Effect.EffectScope.GLOBAL

func can_process(_stage: String, _event: TriggerEvent) -> bool:
	return true

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	event.ctx.should_tick = true
