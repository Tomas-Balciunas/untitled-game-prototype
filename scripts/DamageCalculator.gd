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
	context = event.ctx
	final_damage = event.damage
	base_damage = event.damage
	source = event.actor
	target = event.target
	actor = source.get_actor()

	if actor:
		type = actor.damage_type

	final_damage = _apply_formula()


func _apply_formula() -> float:
	if not actor or not target:
		return base_damage

	var offense: float = _get_offense()
	var defense: float = _get_defense() * (1.0 - defense_ignore / 100.0)
	var denominator: float = max(1.0, offense + defense)

	return base_damage * (offense / denominator)


func _get_offense() -> float:
	match type:
		DamageTypes.Type.PHYSICAL:
			return max(1.0, actor.stats.attack)
		DamageTypes.Type.FIRE, DamageTypes.Type.ICE, DamageTypes.Type.LIGHTNING, DamageTypes.Type.POISON:
			return max(1.0, actor.stats.magic_power)
		DamageTypes.Type.HOLY, DamageTypes.Type.DARK:
			return max(1.0, actor.stats.divine_power)
		_:
			return max(1.0, actor.stats.attack)


func _get_defense() -> float:
	match type:
		DamageTypes.Type.PHYSICAL:
			return max(0.0, target.stats.defense)
		DamageTypes.Type.FIRE, DamageTypes.Type.ICE, DamageTypes.Type.LIGHTNING, DamageTypes.Type.POISON:
			return max(0.0, target.stats.magic_defense)
		DamageTypes.Type.HOLY, DamageTypes.Type.DARK:
			return max(0.0, target.stats.resistance)
		_:
			return max(0.0, target.stats.defense)


func get_final_damage() -> int:
	return max(0, round(final_damage))
