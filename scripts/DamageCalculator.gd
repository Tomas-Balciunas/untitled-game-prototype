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

func _init(event: DamageInstance) -> void:
	context    = event.ctx
	base_damage = event.damage
	final_damage = event.damage
	source     = event.actor
	target     = event.target
	actor      = source.get_actor()

	if actor:
		type = actor.damage_type

	_apply_accuracy_variance()


func _apply_accuracy_variance() -> void:
	var weapon: Weapon = actor.equipment.get("weapon") if actor else null
	var accuracy_range: int = weapon.accuracy_range if weapon else 0

	if accuracy_range == 0:
		return

	var accuracy: float = max(1.0, actor.stats.accuracy if actor else 1.0)
	var evasion: float  = max(1.0, target.stats.evasion if target else 1.0)

	var exponent: float = evasion / accuracy
	var roll: float     = pow(randf(), exponent)

	var damage_min: float = base_damage * (1.0 - accuracy_range / 100.0)
	var damage_max: float = base_damage * (1.0 + accuracy_range / 100.0)

	final_damage = lerpf(damage_min, damage_max, roll)


func get_final_damage() -> int:
	return max(0, round(final_damage))
