extends Trap

class_name ManaDrainTrap

@export var amount: float = 0.2

func trigger(target: CharacterInstance) -> void:
	var drain := ManaDrainEffect.new()
	drain.amount = amount
	drain.immediate_trigger = true
	drain.battle_only = false
	
	var act := ActionContext.new()
	act.actively_cast = false
	act.source = TrapSource.new(self)
	act.set_targets(target)
	
	EffectApplicationResolver.new(drain).execute(act)
