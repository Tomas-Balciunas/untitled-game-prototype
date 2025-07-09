extends Effect
class_name PoisonRes

@export var resistance: float = 0.2

func on_trigger(trigger: String, data: DamageContext) -> void:
	if trigger == "on_receive_damage":
		if data.type == DamageTypes.Type.POISON:
			data.final_value -= (data.final_value * resistance)
			print("Reducing poison damage for %s to %f" % [data.defender.resource.name, data.final_value])
