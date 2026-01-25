extends Node

class_name DamageCalculator

var context: ActionContext = null
var source: ContextSource = null
var actor: CharacterInstance = null
var target: CharacterInstance = null

var type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
var final_damage: float = 0
var base_damage: float = 0
var defense_ignore: int = 0

func _init(event: DamageTriggerEvent) -> void:
	context = event.ctx
	final_damage = event.damage
	base_damage = event.damage
	source = event.actor
	target = event.target
	actor = source.get_actor()
	
	if actor:
		type = actor.damage_type
	

func get_final_damage() -> int:
	return max(0, round(final_damage))
