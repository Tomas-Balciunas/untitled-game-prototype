extends Node
class_name FormationSlotNumbers

const NUMBER = preload("uid://ofehbowovh6w")


func display_damage(amt: int) -> void:
	var line: Label3D = NUMBER.instantiate()
	line.set_notification(str(amt), 1.0)
	
	self.add_child(line)

func display_heal(amt: int) -> void:
	var line: Label3D = NUMBER.instantiate()
	line.modulate = Color(0.0, 0.658, 0.0, 1.0)
	line.set_notification(str(amt), 1.0)
	
	self.add_child(line)
