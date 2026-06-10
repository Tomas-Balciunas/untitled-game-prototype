@abstract
extends Effect
class_name StatusEffect

var category: EffectCategory = EffectCategory.STATUS


func get_category() -> EffectCategory:
	return category
