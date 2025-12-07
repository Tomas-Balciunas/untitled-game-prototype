extends Trap

class_name ManaDrainTrap

@export var amount: float = 0.2

func trigger(target: CharacterInstance) -> void:
	var drain := ManaDrainEffect.new()
	drain.amount = amount
	drain.single_trigger = true
	
	var act := EffectApplicationContext.new()
	act.actively_cast = true
	act.effect = drain
	act.source = TrapSource.new(self)
	act.target = target
	
	EffectApplicationResolver.new().execute(act)
