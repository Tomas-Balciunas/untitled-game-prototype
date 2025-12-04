extends Node
class_name UISlotNumbers

const DAMAGE_NUMBER_2D = preload("uid://burd322348idn")

func display_damage(amt: int) -> void:
	var line: Label = DAMAGE_NUMBER_2D.instantiate()
	line.set_notification(str(amt), 0.8)
	
	self.add_child(line)

func display_heal(amt: int) -> void:
	var line: Label = DAMAGE_NUMBER_2D.instantiate()
	line.modulate = Color(0.0, 0.658, 0.0, 1.0)
	line.set_notification(str(amt), 0.8)
	
	self.add_child(line)
