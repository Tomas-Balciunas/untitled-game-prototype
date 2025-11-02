extends Trap

class_name ManaDrainTrap

@export var amount: float = 0.2

func trigger(target: CharacterInstance) -> void:
	var drain := ManaDrainEffect.new()
	drain.amount = amount
	drain.single_trigger = true
	
	var act := EffectApplicationAction.new()
	act.actively_cast = true
	act.effect = drain
	act.source = get_source()
	act.target = target
	
	EffectApplicationResolver.apply_effect(act)
