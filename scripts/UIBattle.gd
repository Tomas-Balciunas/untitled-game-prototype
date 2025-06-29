extends Control

signal action_selected(action: String)

@onready var attack_button = $VBoxContainer/AttackButton

func _ready():
	attack_button.pressed.connect(_on_attack_pressed)

func _on_attack_pressed():
	emit_signal("action_selected", "attack")
	hide()
