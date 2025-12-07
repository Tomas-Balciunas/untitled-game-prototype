@abstract
extends Effect
class_name BuffEffect

@export var duration_turns: int = -1

var category: EffectCategory = EffectCategory.BUFF


func get_category() -> EffectCategory:
	return category
