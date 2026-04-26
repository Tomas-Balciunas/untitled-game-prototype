extends PassiveEffect

class_name ThornsEffect

@export var reflect_rate: float = 0.15


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_ABOUT_TO_BE_APPLIED]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event is DamageInstance and (event as DamageInstance).target == owner


func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var dmg := event as DamageInstance
	var reflected := maxi(1, roundi(dmg.calculator.get_final_damage() * reflect_rate))
	var attacker := dmg.actor.get_actor()

	if attacker and not attacker.is_dead:
		var new_hp := maxi(0, attacker.state.current_health - reflected)
		attacker.set_current_health(new_hp)
		BattleTextLines.print_line("%s reflects %d damage back to %s!" % [owner.resource.name, reflected, attacker.resource.name])
