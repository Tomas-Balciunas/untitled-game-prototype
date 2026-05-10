extends Node

class_name DamageCalculator

var context: ActionContext = null
var source: ContextSource = null
var actor: CharacterInstance = null
var target: CharacterInstance = null

var type: DamageTypes.Type = DamageTypes.Type.PHYSICAL
var final_damage: float = 0.0
var base_damage: float = 0.0
var accuracy: float = 0.0
var accuracy_range: int = 0
var defense_ignore: int = 0
var is_critical: bool = false
var critical_damage: float = 1.7

func _init(event: DamageInstance) -> void:
	context = event.ctx
	base_damage = event.damage
	final_damage = event.damage
	source = event.source
	target = event.target
	actor = source.get_actor()
	
	if actor:
		accuracy = actor.stats.accuracy
	
	assert(target)
	
	set_damage_type()
	set_accuracy_range()

func calculate_final_damage() -> void:
	apply_accuracy_variance()
	
	final_damage = final_damage - target.stats.defense
	
	if is_critical:
		final_damage = final_damage * critical_damage
	


func apply_accuracy_variance() -> void:
	if accuracy_range == 0 or accuracy == 0.0:
		return

	var accuracy: float = max(1.0, actor.stats.accuracy if actor else 0.0)
	var evasion: float  = max(1.0, target.stats.evasion)

	var exponent: float = evasion / accuracy
	var roll: float = pow(randf(), exponent)

	var damage_min: float = base_damage * (1.0 - accuracy_range / 100.0)
	var damage_max: float = base_damage * (1.0 + accuracy_range / 100.0)

	var result = lerpf(damage_min, damage_max, roll)
	
	if round(result) == round(damage_max):
		is_critical = true
		
	final_damage = result

func get_final_damage() -> int:
	return max(0, round(final_damage))

func set_damage_type() -> void:
	if source.skill and source.skill.get_damage_type():
		type = source.skill.get_damage_type()
		
		return
	
	type = DamageTypes.Type.PHYSICAL

func set_accuracy_range() -> void:
	var weapon: Weapon = actor.equipment.get("weapon") if actor else null
	accuracy_range = weapon.accuracy_range if weapon else 0
	
