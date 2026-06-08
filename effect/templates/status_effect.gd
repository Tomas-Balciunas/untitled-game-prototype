@abstract
extends Effect
class_name StatusEffect

var category: EffectCategory = EffectCategory.STATUS

func _init() -> void:
	expires_after_battle = true


func get_category() -> EffectCategory:
	return category
