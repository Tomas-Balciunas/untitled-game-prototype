extends Control

signal action_selected(action: String, options: Array)

@onready var attack_button = $VBoxContainer/AttackButton
@onready var defend_button = $VBoxContainer/DefendButton
@onready var skill_button = $VBoxContainer/SkillButton
@onready var item_button = $VBoxContainer/ItemButton
@onready var flee_button = $VBoxContainer/FleeButton
@onready var skill_popup = $SkillPopup
@onready var skill_list_container = $SkillPopup/ScrollContainer/SkillListContainer

func _on_defend_button_pressed() -> void:
	emit_signal("action_selected", "defend", [])


func _on_attack_button_pressed() -> void:
	emit_signal("action_selected", "attack", [])


func _on_flee_button_pressed() -> void:
	emit_signal("action_selected", "flee", [])


func _on_skill_selected(skill) -> void:
	emit_signal("action_selected", "skill", [skill])
	skill_popup.hide()


func _on_item_selected(item) -> void:
	emit_signal("action_selected", "item", [item])

func highlight_action(action: String):
	_reset_all_button_highlights()
	
	match action:
		"attack":
			_highlight_button(attack_button)
		"defend":
			_highlight_button(defend_button)
		"flee":
			_highlight_button(flee_button)
		"skill":
			_highlight_button(skill_button)
		"item":
			_highlight_button(item_button)

func _highlight_button(button: Button):
	button.add_theme_color_override("font_color", Color.YELLOW)

func _reset_all_button_highlights():
	var buttons = [attack_button, defend_button, flee_button, skill_button, item_button]
	for b in buttons:
		b.add_theme_color_override("font_color", Color.WHITE)


func _on_skill_button_pressed() -> void:
	_populate_skill_list()
	skill_popup.popup_centered()


func _on_item_button_pressed() -> void:
	pass # Replace with function body.

func _populate_skill_list():
	for child in skill_list_container.get_children():
		child.queue_free()

	var skills = [
		{"name": "Precision Strike",
		"mp_cost": 5}
	]

	for skill in skills:
		var btn = Button.new()
		btn.text = "%s (%d MP)" % [skill["name"], skill["mp_cost"]]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_skill_selected.bind(skill))
		skill_list_container.add_child(btn)
