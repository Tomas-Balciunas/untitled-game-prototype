extends StatusEffect

class_name BerserkEffect

@export var attack_bonus: float = 0.4

var _modifier: StatModifier
var _remaining: int


func on_apply() -> void:
	_modifier = StatModifier.new()
	_modifier.name = "Berserk ATK"
	_modifier.type = StatModifier.Type.MULTIPLICATIVE
	_modifier.stat = Stats.StatRef.ATTACK
	_modifier.value = attack_bonus
	owner.state.add_temporary_modifier(_modifier)
	_remaining = duration_turns
	StatCalculator.recalculate_stat(owner, Stats.StatRef.ATTACK)
	BattleTextLines.print_line("%s goes berserk!" % owner.resource.name)


func on_expire() -> void:
	if _modifier:
		owner.state.remove_temporary_modifier(_modifier)
		StatCalculator.recalculate_stat(owner, Stats.StatRef.ATTACK)
	BattleTextLines.print_line("%s calms down." % owner.resource.name)
	remove_self()


func listened_triggers() -> Array:
	return [EffectTriggers.ON_TURN_START, EffectTriggers.ON_TURN_END]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return owner == event.actor.get_actor()


func on_trigger(stage: String, event: TriggerEvent) -> void:
	if stage == EffectTriggers.ON_TURN_START:
		event.ctx.force_action = true
		event.ctx.initial_target = BattleContext.manager.battlers.pick_random()
		return

	if stage == EffectTriggers.ON_TURN_END and duration_turns > 0:
		_remaining -= 1
		if _remaining <= 0:
			on_expire()
