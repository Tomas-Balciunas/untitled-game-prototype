extends BuffEffect

class_name ManaRegenEffect

@export var mana_per_turn: int = 5

var _remaining: int


func on_apply() -> void:
	_remaining = duration_turns
	BattleTextLines.print_line("%s is recovering mana!" % owner.resource.name)


func on_expire() -> void:
	remove_self()


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START, EffectTriggers.ON_TURN_END]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()


func on_trigger(stage: String, _event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_TURN_START:
		var restored := mini(owner.state.current_mana + mana_per_turn, int(owner.stats.mana))
		owner.set_current_mana(restored)
		BattleTextLines.print_line("%s recovers %d mana!" % [owner.resource.name, mana_per_turn])
		return

	if stage == EffectTriggers.ON_TURN_END and duration_turns > 0:
		_remaining -= 1
		if _remaining <= 0:
			on_expire()
