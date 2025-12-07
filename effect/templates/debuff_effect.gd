@abstract
extends Effect
class_name DebuffEffect

var category: EffectCategory = EffectCategory.DEBUFF

@export var duration_turns: int = -1


func get_category() -> EffectCategory:
	return category
