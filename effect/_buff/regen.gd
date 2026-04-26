extends BuffEffect

class_name RegenEffect

@export var heal_per_turn: int = 10

var _remaining: int


func on_apply() -> void:
	_remaining = duration_turns
	BattleTextLines.print_line("%s is regenerating!" % owner.resource.name)


func on_expire() -> void:
	remove_self()


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START, EffectTriggers.ON_TURN_END]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()


func on_trigger(stage: String, _event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_TURN_START:
		var healed := mini(owner.state.current_health + heal_per_turn, int(owner.stats.health))
		owner.set_current_health(healed)
		BattleTextLines.print_line("%s regenerates %d HP!" % [owner.resource.name, heal_per_turn])
		return

	if stage == EffectTriggers.ON_TURN_END and duration_turns > 0:
		_remaining -= 1
		if _remaining <= 0:
			on_expire()
