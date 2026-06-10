extends TriggerEvent

class_name PoisonEvent


var damage_per_turn: int = 0
var power: float = 1.0

func from_poison(poison: PoisonEffect) -> void:
	damage_per_turn = poison.damage_per_turn
