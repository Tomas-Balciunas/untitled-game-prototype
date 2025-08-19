extends Control

signal action_selected(action: String, options: Array)

var current_battler: CharacterInstance = null

@onready var attack_button = $VBoxContainer/AttackButton
@onready var defend_button = $VBoxContainer/DefendButton
@onready var skill_button = $VBoxContainer/SkillButton
@onready var item_button = $VBoxContainer/ItemButton
@onready var flee_button = $VBoxContainer/FleeButton
@onready var skill_popup = $Skill/SkillPopup
@onready var skill_list_container = $Skill/SkillPopup/ScrollContainer/SkillListContainer
@onready var item_popup = $Item/ItemPopup
@onready var item_list_container = $Item/ItemPopup/ScrollContainer/ItemListContainer

func _on_battler_change(battler, is_party_member: bool):
	if is_party_member:
		current_battler = battler
	
func _on_turn_started(is_party_member: bool):
	if is_party_member:
		show()
		highlight_action("attack")
	else:
		hide()

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
	_populate_item_list()
	item_popup.popup_centered()
	
func _populate_item_list():
	for child in item_list_container.get_children():
		child.queue_free()

	var items = current_battler.inventory.get_all_items()
	for item in items:
		if not item is ConsumableItem:
			continue
		var btn = Button.new()
		btn.text = item.name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_item_selected.bind(item))
		item_list_container.add_child(btn)

func _populate_skill_list():
	for child in skill_list_container.get_children():
		child.queue_free()

	var skills = []
	for s in current_battler.learnt_skills:
		skills.append(s)
	
	for skill in skills:
		var mp_cost = skill.mp_cost
		
		for e in current_battler.effects:
			if e.has_method("modify_mp_cost"):
				mp_cost = e.modify_mp_cost(mp_cost)
				
		var btn = Button.new()
		btn.text = "%s (%d MP)" % [skill["name"], mp_cost]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_skill_selected.bind(skill))
		
		if current_battler.stats.current_mana < mp_cost:
			btn.disabled = true
		
		skill_list_container.add_child(btn)
