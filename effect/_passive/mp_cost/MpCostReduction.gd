extends Effect

class_name MpCostReduction

@export var modifier: float = 0.2

func listened_triggers() -> Array:
	return []

func modify_mp_cost(mp_cost: int) -> int:
	return round(mp_cost * (1.0 - modifier))
