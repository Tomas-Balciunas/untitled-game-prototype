extends PassiveEffect

class_name LifestealEffect

@export var rate: float = 0.2


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event is DamageInstance and event.actor.get_actor() == owner


func on_trigger(_stage: String, event: TriggerEvent) -> void:
	var dmg := event as DamageInstance
	var healed := maxi(1, roundi(dmg.calculator.get_final_damage() * rate))
	var new_hp := mini(owner.state.current_health + healed, int(owner.stats.health))
	owner.set_current_health(new_hp)
	BattleTextLines.print_line("%s steals %d HP!" % [owner.resource.name, healed])
