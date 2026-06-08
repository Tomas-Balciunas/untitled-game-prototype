@abstract
extends Effect
class_name DebuffEffect

var category: EffectCategory = EffectCategory.DEBUFF

func _init() -> void:
	expires_after_battle = true


func get_category() -> EffectCategory:
	return category
