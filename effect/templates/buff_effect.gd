@abstract
extends Effect
class_name BuffEffect

@export var duration_turns: int = -1

var category: EffectCategory = EffectCategory.BUFF

func _init() -> void:
	expires_after_battle = true


func get_category() -> EffectCategory:
	return category
