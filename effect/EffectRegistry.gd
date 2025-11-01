extends Node

var effects := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths := [
		"res://effect/_offensive/armor_pierce/ArmorPierce.tres",
		"res://effect/_offensive/poison/poison on hit.tres",
		"res://effect/_passive/counterattack/Counterattack.tres",
		"res://effect/_passive/damage share/DamageShare.tres",
		"res://effect/_passive/healing/HealBoost.tres",
		"res://effect/_passive/mp_cost/MpCostReduction.tres",
		"res://effect/_passive/resistance poison/PoisonRes.tres",
		"res://gear/consumable/hp pot minor/heal_on_consume_effect.tres",
		"res://gear/consumable/poison flask minor/poison_on_consume_effect.tres",
	]
	
	for path: String in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_effect(res)

func register_effect(effect: Effect) -> void:
	if effect.id in effects:
		push_warning("Duplicate effect id: %s" % effect.id)
	effects[effect.id] = effect

func get_effect(id: String) -> Effect:
	if effects.has(id):
		return effects[id]
	return null

func get_all_effects() -> Array:
	return effects.values()
