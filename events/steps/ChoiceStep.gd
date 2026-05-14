extends EventStep
class_name ChoiceStep

@export var text: String = ""
@export var choices: Array[ChoiceOption] = []


func run(manager: EventManager) -> void:
	ConversationBus.request_choice.emit(text, choices)
	var choice: String = await ConversationBus.choice_made
	manager.choices.append(choice)


static func prompt(p_text: String, p_choices: Array[ChoiceOption]) -> ChoiceStep:
	var s := ChoiceStep.new()
	s.text = p_text
	s.choices = p_choices
	return s
