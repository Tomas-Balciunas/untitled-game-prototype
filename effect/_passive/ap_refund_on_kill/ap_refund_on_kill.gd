extends BuffEffect
class_name ApRefundOnKill

func listened_triggers() -> Array:
	return [EffectTriggers.ON_DEATH]

func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner_is_actor(event) and event.target.is_dead

func on_trigger(_stage: String, event: TriggerEvent) -> void:
	if event.source.skill:
		event.ctx.turn.add_action_points(1)
