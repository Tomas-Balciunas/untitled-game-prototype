extends Control

signal text_advance

@export var show_speed: float = 0.02
@onready var speaker_label = $Panel/SpeakerLabel
@onready var text_label    = $Panel/TextLabel
@onready var panel         = $Panel

var full_text: String = ""
var char_index: int = 0
var typing_timer: Timer

func _ready():
	ConversationManager.request_dialogue.connect(_on_request_dialogue)
	hide()
	typing_timer = Timer.new()
	add_child(typing_timer)
	typing_timer.wait_time = show_speed
	typing_timer.one_shot = false
	typing_timer.connect("timeout", Callable(self, "_on_typing_tick"))
	
func _on_request_dialogue(speaker: String, lines: Array):
	show()
	await _play_lines(speaker, lines)
	ConversationManager.notify_finished()
	
func _play_lines(speaker: String, lines: Array) -> void:
	for line in lines:
		await show_text(speaker, line)

func show_text(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	full_text = text
	char_index = 0
	text_label.text = ""
	panel.visible = true
	show()
	typing_timer.start()
	await text_advance

func _on_typing_tick():
	if char_index < full_text.length():
		text_label.text += full_text[char_index]
		char_index += 1
	else:
		typing_timer.stop()

func _unhandled_input(event):
	if not is_visible():
		return
		
	if event.is_action_pressed("ui_accept"):
		if typing_timer.is_stopped():
			hide()
			emit_signal("text_advance")
		else:
			# fast-forward
			typing_timer.stop()
			text_label.text = full_text
