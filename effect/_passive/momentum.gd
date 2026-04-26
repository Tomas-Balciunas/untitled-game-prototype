extends PassiveEffect

class_name MomentumEffect

@export var bonus_per_stack: float = 0.1
@export var max_stacks: int = 5

var _stacks: int = 0


func listened_triggers() -> Array:
	return [EffectTriggers.ON_HIT, EffectTriggers.ON_DAMAGE_APPLIED]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	return event is DamageInstance


func on_trigger(stage: String, event: TriggerEvent) -> void:
	var dmg := event as DamageInstance

	if stage == EffectTriggers.ON_HIT and dmg.actor.get_actor() == owner and _stacks > 0:
		dmg.calculator.final_damage += dmg.calculator.final_damage * (bonus_per_stack * _stacks)
		return

	if stage == EffectTriggers.ON_DAMAGE_APPLIED:
		if dmg.actor.get_actor() == owner:
			_stacks = mini(_stacks + 1, max_stacks)
		elif dmg.target == owner:
			if _stacks > 0:
				BattleTextLines.print_line("%s loses momentum!" % owner.resource.name)
			_stacks = 0
