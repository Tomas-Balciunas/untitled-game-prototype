extends ActionContext

class_name DamageContext

var type: DamageTypes.Type
var base_value: float


func _init(damage: float) -> void:
	base_value = damage
