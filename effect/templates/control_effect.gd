@abstract
extends Effect
class_name ControlEffect

var category: EffectCategory = EffectCategory.CONTROL

func _init() -> void:
	expires_after_battle = true

func get_category() -> EffectCategory:
	return category
