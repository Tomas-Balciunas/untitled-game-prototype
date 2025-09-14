extends EventStep
class_name DialogueStep

var speaker: String
var lines: Array

func _init(data: Dictionary):
	speaker = data.get("speaker", "Unknown Entity")
	lines = data.get("text", [])

func run(_manager: Node) -> void:
	ConversationBus.request_conversation.emit(speaker, lines)
	await ConversationBus.conversation_finished
