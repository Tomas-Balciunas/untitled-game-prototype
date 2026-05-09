extends Node
class_name FormationSlotNumbers

const NUMBER = preload("uid://ofehbowovh6w")


func display_damage(damage_instance: DamageInstance) -> void:
	var line: Label3D = NUMBER.instantiate()
	if damage_instance.calculator.is_critical:
		line.modulate = Color(0.772, 0.124, 0.17, 1.0)
	line.set_notification(str(damage_instance.calculator.get_final_damage()), 1.0)
	
	self.add_child(line)

func display_heal(amt: int) -> void:
	var line: Label3D = NUMBER.instantiate()
	line.modulate = Color(0.0, 0.658, 0.0, 1.0)
	line.set_notification(str(amt), 1.0)
	
	self.add_child(line)
