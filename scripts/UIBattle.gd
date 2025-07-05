extends Control

signal action_selected(action: String, options: Array)

@onready var attack_button = $VBoxContainer/AttackButton
@onready var defend_button = $VBoxContainer/DefendButton

func _on_defend_button_pressed() -> void:
	emit_signal("action_selected", "defend", [])


func _on_attack_button_pressed() -> void:
	emit_signal("action_selected", "attack", [])


func _on_flee_button_pressed() -> void:
	emit_signal("action_selected", "flee", [])


func _on_skill_button_item_selected(index: int) -> void:
	emit_signal("action_selected", "skill", [])


func _on_item_button_item_selected(index: int) -> void:
	emit_signal("action_selected", "item", [])
