extends TriggerEvent

class_name DamageInstance

signal hit_confirmed

var calculator: DamageCalculator
var target: CharacterInstance
var damage: int

func _init(c: ActionContext, t: CharacterInstance, amount: int) -> void:
	ctx = c
	actor = c.source
	target = t
	damage = amount
	calculator = DamageCalculator.new(self)
