@abstract
extends Effect
class_name StatusEffect

var category: EffectCategory = EffectCategory.STATUS

@export var duration_turns: int = -1


func get_category() -> EffectCategory:
	return category
