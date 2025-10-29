extends EventStep
class_name DialogueStep

var speaker: String
var lines: Array

func _init(data: Dictionary) -> void:
	speaker = data.get("speaker", "")
	lines = data.get("text", [])

func run(_manager: Node) -> void:
	ConversationBus.request_conversation.emit(speaker, lines)
	await ConversationBus.conversation_finished
