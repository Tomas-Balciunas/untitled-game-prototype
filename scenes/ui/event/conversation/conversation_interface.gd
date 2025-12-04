extends Node

@onready var textbox: TextboxUI = $TextboxUI


func init_conversation(speaker: String, lines: Array) -> void:
	await _play_lines(speaker, lines)
	ConversationBus.conversation_finished.emit()

func _play_lines(speaker: String, lines: Array) -> void:
	for line: String in lines:
		textbox.show_line(speaker, line)
		await textbox.finished_line
