extends DebuffEffect

class_name BlindEffect

@export var miss_chance: float = 0.5

var _remaining: int


func on_apply() -> void:
	_remaining = duration_turns
	BattleTextLines.print_line("%s is blinded!" % owner.resource.name)


func on_expire() -> void:
	BattleTextLines.print_line("%s can see again!" % owner.resource.name)
	remove_self()


func listened_triggers() -> Array:
	return [EffectTriggers.ON_HIT, EffectTriggers.ON_TURN_END]


func can_process(stage: String, event: TriggerEvent) -> bool:
	if stage == EffectTriggers.ON_HIT:
		return event is DamageInstance and event.actor.get_actor() == owner
	return owner == event.actor.get_actor()


func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_HIT:
		if randf() < miss_chance:
			(event as DamageInstance).calculator.final_damage = 0
			BattleTextLines.print_line("%s misses!" % owner.resource.name)
		return

	if duration_turns > 0:
		_remaining -= 1
		if _remaining <= 0:
			on_expire()
