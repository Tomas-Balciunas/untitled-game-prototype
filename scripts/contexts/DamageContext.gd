extends ActionContext

class_name DamageContext

var type: DamageTypes.Type
var base_value: int
var final_value: float
var calculator: DamageCalculator


func _init(_damage: float) -> void:
	calculator = DamageCalculator.new(self, _damage)
