extends ControlEffect

class_name SleepEffect


func on_apply() -> void:
	BattleTextLines.print_line("%s falls asleep!" % owner.resource.name)


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START, EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor() or (event is DamageInstance and (event as DamageInstance).target == owner)


func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_TURN_START:
		event.ctx.skip_turn = true
		return

	if stage == EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE:
		BattleTextLines.print_line("%s wakes up!" % owner.resource.name)
		owner.remove_effect(self)
