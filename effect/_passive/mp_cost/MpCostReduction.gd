extends Effect

class_name MpCostReduction

@export var modifier: float = 0.2

func on_trigger(trigger, ctx):
	pass

func modify_mp_cost(mp_cost: int) -> int:
	return round(mp_cost * (1.0 - modifier))
