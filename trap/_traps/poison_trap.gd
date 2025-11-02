extends Trap

class_name PoisonTrap

@export var duration: int = 3
@export var damage_per_turn: int = 7

func trigger(target: CharacterInstance) -> void:
	var poison := PoisonOnHit.new()
	poison.duration_turns = duration
	poison.damage_per_turn = damage_per_turn
	
	var act := AttackAction.new()
	act.defender = target
	act.attacker = get_source()
	act.base_value = damage if damage else 0
	act.actively_cast = true
	act.effects.append(poison)
	
	DamageResolver.apply_attack(act)
