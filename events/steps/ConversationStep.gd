extends EventStep
class_name DialogueStep

@export var speaker: String = ""
@export var lines: Array[String] = []


func run(_manager: EventManager) -> void:
	ConversationBus.request_conversation.emit(speaker, lines)
	await ConversationBus.conversation_finished


static func say(p_speaker: String, p_lines: Array) -> DialogueStep:
	var s := DialogueStep.new()
	s.speaker = p_speaker
	var typed: Array[String] = []
	for l in p_lines:
		typed.append(l)
	s.lines = typed
	return s
