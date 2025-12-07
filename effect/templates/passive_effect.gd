@abstract
extends Effect
class_name PassiveEffect

var category: EffectCategory = EffectCategory.PASSIVE


func get_category() -> EffectCategory:
	return category
