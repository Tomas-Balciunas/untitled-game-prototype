extends PassiveEffect

class_name BounceIncreasingDamage


func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor() and event is DamageInstance


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	var event: DamageInstance = _event
	
	if !event.ctx.options.has("total_bounces") and !event.ctx.options.has("current_bounce"):
		return
	
	var current: int = event.ctx.options.get("current_bounce")
	
	if current <= 1:
		return
	
	event.calculator.final_damage *= 1 + ((current - 1) / 10.0)
