extends Node
class_name SmallChatter

const CHATTER_LINE_3D = preload("uid://cxmmcwtj68dos")

func chatter(text: String) -> void:
	var line: Label3D = CHATTER_LINE_3D.instantiate()
	self.add_child(line)
	line.chat(text)
