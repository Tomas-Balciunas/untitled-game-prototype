@abstract
extends Effect
class_name BuffEffect

var category: EffectCategory = EffectCategory.BUFF

func _init() -> void:
	expires_after_battle = true


func get_category() -> EffectCategory:
	return category
