extends Node

@onready var textbox: TextboxUI = $TextboxUI

func _ready() -> void:
	ConversationBus.request_conversation.connect(_on_request_dialogue)

func _on_request_dialogue(speaker: String, lines: Array) -> void:
	await _play_lines(speaker, lines)
	ConversationBus.conversation_finished.emit()

func _play_lines(speaker: String, lines: Array) -> void:
	for line in lines:
		textbox.show_line(speaker, line)
		await textbox.finished_line

#func notify_choice(index: int):
	#choice_made.emit(index)

#func show_choices(speaker: String, prompt: String, options: Array[String]) -> int:
	#if not _textbox_ui:
		#return -1
	#
	#await _textbox_ui.show_text(speaker, prompt)
	#
	#var choice_index = await _textbox_ui.show_choice_menu(options)
	#emit_signal("choice_made", choice_index)
	#return choice_index
