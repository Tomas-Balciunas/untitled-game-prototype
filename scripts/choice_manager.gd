extends Node

const CHOICE_UI = preload("uid://dxe21eqylwhoq")


func init_choice(text: String, choices: Array) -> void:
	var inst := CHOICE_UI.instantiate()
	add_child(inst)
	inst.bind(text, choices)
	
