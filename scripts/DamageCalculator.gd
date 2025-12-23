extends Node

class_name DamageCalculator

var context: DamageContext = null
var final_damage: float = 0
var base_damage: float = 0
var defense_ignore: int = 0

func _init(ctx: DamageContext, dmg: float) -> void:
	context = ctx
	base_damage = dmg
	final_damage = dmg

func get_final_damage() -> float:
		
	return final_damage
