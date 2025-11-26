extends Node

const CHOICE_UI = preload("uid://dxe21eqylwhoq")

func _ready() -> void:
	ConversationBus.request_choice.connect(_on_choice_requested)


func _on_choice_requested(text: String, choices: Array) -> void:
	var inst := CHOICE_UI.instantiate()
	add_child(inst)
	inst.bind(text, choices)
	
