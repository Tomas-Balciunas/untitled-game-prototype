extends Node

class_name DamageCalculator

var context: DamageContext = null
var final_damage: float = 0
var base_damage: float = 0
var defense_ignore: int = 0

func _init(ctx: DamageContext) -> void:
	context = ctx
	base_damage = context.base_value
	final_damage = context.base_value

func get_final_damage() -> int:
	return max(0, round(final_damage))
