extends Trap

class_name PoisonTrap

@export var duration: int = 3
@export var damage_per_turn: int = 7

func trigger(target: CharacterInstance) -> void:
	var poison := PoisonOnHit.new()
	poison.duration_turns = duration
	poison.damage_per_turn = damage_per_turn
	
	var damage_value: int = damage if damage else 0
	
	var act := DamageContext.new(damage_value)
	act.target = target
	act.source = TrapSource.new(self)
	act.base_value = damage_value
	act.final_value = damage_value
	act.actively_cast = true
	act.temporary_effects.append(poison)
	
	DamageResolver.new().execute(act)
