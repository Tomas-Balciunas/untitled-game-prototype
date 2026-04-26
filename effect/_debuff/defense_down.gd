extends DebuffEffect

class_name DefenseDownEffect

@export var value: int = 10

var _modifier: StatModifier
var _remaining: int


func on_apply() -> void:
	_modifier = StatModifier.new()
	_modifier.name = "Defense-"
	_modifier.type = StatModifier.Type.ADDITIVE
	_modifier.stat = Stats.StatRef.DEFENSE
	_modifier.value = -value
	owner.state.add_temporary_modifier(_modifier)
	_remaining = duration_turns
	StatCalculator.recalculate_stat(owner, Stats.StatRef.DEFENSE)
	BattleTextLines.print_line("%s's defense is lowered!" % owner.resource.name)


func on_expire() -> void:
	if _modifier:
		owner.state.remove_temporary_modifier(_modifier)
		StatCalculator.recalculate_stat(owner, Stats.StatRef.DEFENSE)
	remove_self()


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_END]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	if duration_turns > 0:
		_remaining -= 1
		if _remaining <= 0:
			on_expire()
