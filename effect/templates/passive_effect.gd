@abstract
extends Effect
class_name PassiveEffect

var category: EffectCategory = EffectCategory.PASSIVE


## Passives are native (innate) and shown in the character menu, not the
## transient status screen. Subclasses overriding _init must call super().
func _init() -> void:
	native = true
	show_in_status = false


func get_category() -> EffectCategory:
	return category
