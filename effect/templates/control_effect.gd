@abstract
extends Effect
class_name ControlEffect

var category: EffectCategory = EffectCategory.CONTROL

@export var duration_turns: int = -1

func _init() -> void:
	expires_after_battle = true

func get_category() -> EffectCategory:
	return category
