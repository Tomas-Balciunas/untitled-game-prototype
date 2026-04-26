extends PassiveEffect

class_name ManaShieldEffect

@export var efficiency: float = 1.0


func listened_triggers() -> Array:
	return [EffectTriggers.ON_BEFORE_RECEIVE_DAMAGE]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event is DamageInstance and (event as DamageInstance).target == owner


func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var dmg := event as DamageInstance
	if owner.state.current_mana <= 0:
		return

	var incoming := dmg.calculator.final_damage
	var max_absorbable := owner.state.current_mana * efficiency
	var absorbed := minf(incoming, max_absorbable)
	var mana_cost := ceili(absorbed / efficiency)

	dmg.calculator.final_damage -= absorbed
	owner.set_current_mana(owner.state.current_mana - mana_cost)

	BattleTextLines.print_line(
		"%s's mana shield absorbs %d damage! (%d mana consumed)" % [owner.resource.name, roundi(absorbed), mana_cost]
	)
