extends EventStep
class_name ChoiceStep

const CHOICES = CharacterInteraction.CHOICES
const BTN_TEXT = CharacterInteraction.BTN_TEXT

var text: String
var choices: Array

func _init(data: Dictionary) -> void:
	choices = data.get(CHOICES, "")
	text = data.get(EventManager.TEXT, "")

func run(_manager: EventManager) -> void:
	ConversationBus.request_choice.emit(text, choices)
	var choice: String = await ConversationBus.choice_made
	_manager.choices.append(choice)
