extends Trap

class_name PoisonTrap

@export var duration: int = 3
@export var damage_per_turn: int = 7

func trigger(target: Character) -> void:
	var poison := PoisonEffect.new()
	poison.duration_turns = duration
	poison.damage_per_turn = damage_per_turn
	
	var damage_value: int = damage if damage else 0
	
	var act := ActionContext.new()
	act.set_targets(target)
	act.source = TrapSource.new(self)
	act.actively_cast = true

	DamageResolver.new(damage_value).execute(act)
	EffectApplicationResolver.new(poison).execute(act)
