extends Node

class_name DamageCalculator

var context: DamageContext = null
var defense_ignore: int = 0

func _init(ctx: DamageContext, pierce: int = 0):
	context = ctx
	defense_ignore = pierce

func get_final_damage() -> int:
	var final = context.final_value
	
	#if context.type == DamageTypes.Type.PHYSICAL:
	#if context.options.has("dot") and not context.options.has("dot"): 
		#final -= context.target.stats.defense * 1 - defense_ignore
		
	return final
