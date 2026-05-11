extends TriggerEvent

class_name DamageInstance

signal hit_confirmed

var calculator: DamageCalculator
var damage: int

func _init(c: ActionContext, t: Character, amount: int) -> void:
	ctx = c
	source = c.source
	target = t
	damage = amount
	calculator = DamageCalculator.new(self)
