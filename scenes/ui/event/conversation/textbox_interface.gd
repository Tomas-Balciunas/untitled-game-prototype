extends Control
class_name TextboxUI

signal finished_line

@export var show_speed: float = 0.02

@onready var speaker_label: Label = $Panel/SpeakerLabel
@onready var text_label: Label    = $Panel/TextLabel
@onready var panel: Panel         = $Panel
@onready var typing_timer: Timer  = Timer.new()

var full_text := ""
var char_index := 0

func _ready() -> void:
	hide()
	add_child(typing_timer)
	typing_timer.wait_time = show_speed
	typing_timer.one_shot = false
	typing_timer.timeout.connect(_on_typing_tick)

func show_line(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	full_text = text
	char_index = 0
	text_label.text = ""
	panel.visible = true
	show()
	typing_timer.start()

func _on_typing_tick() -> void:
	if char_index < full_text.length():
		text_label.text += full_text[char_index]
		char_index += 1
	else:
		typing_timer.stop()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	
	if event.is_action_pressed("ui_accept"):
		if typing_timer.is_stopped():
			hide()
			emit_signal("finished_line")
		else:
			typing_timer.stop()
			text_label.text = full_text
