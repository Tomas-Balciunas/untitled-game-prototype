extends PassiveEffect

class_name RiposteEffect

@export var bonus: float = 0.5

var _primed: bool = false


func listened_triggers() -> Array:
	return [EffectTriggers.ON_DAMAGE_APPLIED, EffectTriggers.ON_HIT]


func can_process(_stage: String, event: TriggerEvent) -> bool:
	if not event is DamageInstance:
		return false
	var dmg := event as DamageInstance
	if _stage == EffectTriggers.ON_HIT:
		return dmg.actor.get_actor() == owner and _primed
	return dmg.target == owner or dmg.actor.get_actor() == owner


func on_trigger(stage: String, event: TriggerEvent) -> void:
	var dmg := event as DamageInstance

	if stage == EffectTriggers.ON_HIT and dmg.actor.get_actor() == owner and _primed:
		dmg.calculator.final_damage += dmg.calculator.final_damage * bonus
		_primed = false
		BattleTextLines.print_line("%s ripostes with extra force!" % owner.resource.name)
		return

	if stage == EffectTriggers.ON_DAMAGE_APPLIED and dmg.target == owner:
		_primed = true
