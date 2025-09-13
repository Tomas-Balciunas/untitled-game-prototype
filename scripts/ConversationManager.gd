extends Node

signal request_dialogue(speaker: String, lines: Array)
signal dialogue_finished
signal choice_made(index: int)

func show_dialogue(speaker: String, lines: Array):
	request_dialogue.emit(speaker, lines)

func notify_finished():
	dialogue_finished.emit()

func notify_choice(index: int):
	choice_made.emit(index)

#func show_choices(speaker: String, prompt: String, options: Array[String]) -> int:
	#if not _textbox_ui:
		#return -1
	#
	#await _textbox_ui.show_text(speaker, prompt)
	#
	#var choice_index = await _textbox_ui.show_choice_menu(options)
	#emit_signal("choice_made", choice_index)
	#return choice_index
