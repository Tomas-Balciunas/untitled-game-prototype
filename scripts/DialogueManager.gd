extends Node

signal dialogue_finished
signal choice_made(index: int)

var _textbox_ui: Node = null

func _ready():
	_textbox_ui = get_textbox_ui()

func get_textbox_ui() -> Node:
	var scene = get_tree().current_scene
	if scene and scene.has_node("UIRoot/TextboxUI"):
		return scene.get_node("UIRoot/TextboxUI")
	else:
		push_warning("TextboxUI not found!")
		return null

func show_dialogue(speaker: String, lines: Array) -> void:
	if not _textbox_ui:
		return
	
	for line: String in lines:
		await _textbox_ui.show_text(speaker, line)
	
	emit_signal("dialogue_finished")

func show_choices(speaker: String, prompt: String, options: Array[String]) -> int:
	if not _textbox_ui:
		return -1
	
	await _textbox_ui.show_text(speaker, prompt)
	
	var choice_index = await _textbox_ui.show_choice_menu(options)
	emit_signal("choice_made", choice_index)
	return choice_index
