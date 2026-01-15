extends TriggerEvent

class_name DamageTriggerEvent

var calculator: DamageCalculator

func _init(c: DamageContext, t: CharacterInstance) -> void:
	calculator = DamageCalculator.new(c)
	ctx = c
	actor = c.source
	target = t
