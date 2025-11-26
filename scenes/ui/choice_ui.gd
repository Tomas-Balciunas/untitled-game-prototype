extends Node

@onready var choices_container: VBoxContainer = $Choices
@onready var choice_text: Label = $ChoiceText

func bind(text: String, choices: Array) -> void:
	for c in choices:
		var btn := Button.new()
		btn.text = c["btn_text"]
		choices_container.add_child(btn)
		btn.pressed.connect(_on_choice_made.bind(c["id"]), CONNECT_ONE_SHOT)
	
	choice_text.text = text


func _on_choice_made(choice: String) -> void:
	ConversationBus.choice_made.emit(choice)
	queue_free()
