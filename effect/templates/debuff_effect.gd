@abstract
extends Effect
class_name DebuffEffect

var category: EffectCategory = EffectCategory.DEBUFF

@export var duration_turns: int = -1

func _init() -> void:
	expires_after_battle = true


func get_category() -> EffectCategory:
	return category
