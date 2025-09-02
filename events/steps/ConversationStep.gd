extends EventStep
class_name DialogueStep

var speaker: String
var lines: Array

func _init(data: Dictionary):
	speaker = data.get("speaker", "Unknown Entity")
	lines = data.get("text", [])

func run(_manager: Node) -> void:
	ConversationManager.show_dialogue(speaker, lines)
	await ConversationManager.dialogue_finished
