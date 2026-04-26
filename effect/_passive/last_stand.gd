extends PassiveEffect

class_name LastStandEffect

@export var threshold: float = 0.25
@export var bonus_multiplier: float = 0.6

var _modifier: StatModifier
var _is_active: bool = false


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()


func on_trigger(_stage: String, _event: TriggerEvent) -> void:
	var hp_ratio := float(owner.state.current_health) / float(owner.stats.health)
	var should_be_active := hp_ratio <= threshold

	if should_be_active and not _is_active:
		_modifier = StatModifier.new()
		_modifier.name = "Last Stand"
		_modifier.type = StatModifier.Type.MULTIPLICATIVE
		_modifier.stat = Stats.StatRef.ATTACK
		_modifier.value = bonus_multiplier
		owner.state.add_temporary_modifier(_modifier)
		StatCalculator.recalculate_stat(owner, Stats.StatRef.ATTACK)
		_is_active = true
		BattleTextLines.print_line("%s fights with desperate fury!" % owner.resource.name)
	elif not should_be_active and _is_active:
		owner.state.remove_temporary_modifier(_modifier)
		StatCalculator.recalculate_stat(owner, Stats.StatRef.ATTACK)
		_is_active = false
