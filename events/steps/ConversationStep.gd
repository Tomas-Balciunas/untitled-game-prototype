extends EventStep
class_name DialogueStep

@export var speaker: String = ""
@export var lines: Array[String] = []


func run(_manager: EventManager) -> void:
	ConversationBus.request_conversation.emit(speaker, lines)
	await ConversationBus.conversation_finished
