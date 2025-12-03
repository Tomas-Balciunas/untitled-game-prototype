extends EventStep
class_name DialogueStep

var speaker: String
var lines: Array
var conditions

func _init(data: Dictionary) -> void:
	speaker = data.get("speaker", "")
	lines = data.get("text", [])
	conditions = data.get("conditions", null)

func run(_manager: EventManager) -> void:
	if conditions:
		var passes := true
		for c in conditions:
			if not _manager.choices.has(c):
				passes = false
		
		if not passes:
			return
	
	ConversationBus.request_conversation.emit(speaker, lines)
	await ConversationBus.conversation_finished
