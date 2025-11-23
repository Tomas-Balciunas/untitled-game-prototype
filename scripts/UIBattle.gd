extends Control


var current_battler: CharacterInstance = null

@onready var attack_button := $VBoxContainer/AttackButton
@onready var defend_button := $VBoxContainer/DefendButton
@onready var skill_button := $VBoxContainer/SkillButton
@onready var item_button := $VBoxContainer/ItemButton
@onready var flee_button := $VBoxContainer/FleeButton
@onready var skill_popup := $Skill
@onready var skill_list_container := $Skill/ScrollContainer/SkillListContainer
@onready var item_popup := $Item
@onready var item_list_container := $Item/ScrollContainer/ItemListContainer

@onready var skill_info_panel := $Skill/SkillInfoPanel
@onready var skill_info_name_label := $Skill/SkillInfoPanel/SkillName
@onready var skill_info_cost_label := $Skill/SkillInfoPanel/SkillCost
@onready var skill_info_description_label := $Skill/SkillInfoPanel/SkillDescription

@onready var item_info_panel := $Item/ItemInfoPanel
@onready var item_info_name_label := $Item/ItemInfoPanel/ItemName
@onready var item_info_description_label := $Item/ItemInfoPanel/ItemDescription
@onready var v_box_container_2: VBoxContainer = $VBoxContainer2

func _ready() -> void:
	BattleBus.queue_processed.connect(_on_queue_processed)

func _on_queue_processed(queue: Array[CharacterInstance]) -> void:
	for child in v_box_container_2.get_children():
		child.queue_free()
	var index := 1
	var label2 := Label.new()
	label2.text = "Current. %s av: %s" % [BattleContext.manager.current_battler.resource.name if current_battler else "", BattleContext.manager.current_battler.action_value if current_battler else ""]
	v_box_container_2.add_child(label2)
	for c: CharacterInstance in queue:
		var label := Label.new()
		label.text = "%s. %s - action val.: %s" % [index if index > 1 else "Next", c.resource.name, c.action_value]
		index += 1
		v_box_container_2.add_child(label)

func _on_battler_change(battler: CharacterInstance, is_party_member: bool) -> void:
	if is_party_member:
		current_battler = battler
		_populate_skill_list()
		_populate_item_list()
	
func _on_turn_started(is_party_member: bool) -> void:
	if is_party_member:
		show()
		skill_popup.visible = false
		item_popup.visible = false
		highlight_action("attack")
	#else:
		#hide()

func _on_defend_button_pressed() -> void:
	BattleBus.action_selected.emit(BattleBus.DEFEND, null)

func _on_attack_button_pressed() -> void:
	BattleBus.action_selected.emit(BattleBus.ATTACK, null)
	skill_popup.visible = false
	item_popup.visible = false

func _on_flee_button_pressed() -> void:
	BattleBus.action_selected.emit(BattleBus.FLEE, null)

func _on_skill_selected(skill: Skill) -> void:
	BattleBus.action_selected.emit(BattleBus.SKILL, skill)
	skill_popup.visible = false

func _on_item_selected(item: ConsumableInstance) -> void:
	BattleBus.action_selected.emit(BattleBus.ITEM, item)
	skill_popup.hide()

func highlight_action(action: String) -> void:
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

func _highlight_button(button: Button) -> void:
	button.add_theme_color_override("font_color", Color.YELLOW)

func _reset_all_button_highlights() -> void:
	var buttons := [attack_button, defend_button, flee_button, skill_button, item_button]
	for b: Button in buttons:
		b.add_theme_color_override("font_color", Color.WHITE)

func _on_skill_button_pressed() -> void:
	_populate_skill_list()
	skill_popup.visible = true
	item_popup.visible = false

func _on_item_button_pressed() -> void:
	_populate_item_list()
	item_popup.visible = true
	skill_popup.visible = false
	
func _populate_item_list() -> void:
	for child in item_list_container.get_children():
		child.queue_free()

	var items := current_battler.inventory.get_all_items()
	for item in items:
		if not item is ConsumableInstance:
			continue
		var btn := Button.new()
		btn.text = item.get_item_name()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_item_selected.bind(item))
		btn.mouse_entered.connect(_on_item_hover.bind(item))
		btn.mouse_exited.connect(_on_item_unhover)
		item_list_container.add_child(btn)

func _populate_skill_list() -> void:
	for child in skill_list_container.get_children():
		child.queue_free()

	var skills := []
	for s in current_battler.learnt_skills:
		skills.append(s)
	
	for skill: Skill in skills:
		var mp_cost := skill.mp_cost
		
		for e in current_battler.effects:
			if e.has_method("modify_mp_cost"):
				mp_cost = e.modify_mp_cost(mp_cost)
				
		var btn := Button.new()
		btn.text = "%s (%d MP)" % [skill["name"], mp_cost]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_skill_selected.bind(skill))
		btn.mouse_entered.connect(_on_skill_hover.bind(skill))
		btn.mouse_exited.connect(_on_skill_unhover)
		
		if current_battler.stats.current_mana < mp_cost:
			btn.disabled = true
		
		skill_list_container.add_child(btn)

func _on_skill_hover(skill: Skill) -> void:
	skill_info_panel.visible = true
	skill_info_name_label.text = skill.name
	skill_info_cost_label.text = "MP: %s, SP: %s" % [skill.mp_cost, skill.sp_cost]
	skill_info_description_label.text = skill.description

func _on_skill_unhover() -> void:
	skill_info_panel.visible = false
	
func _on_item_hover(item: ConsumableInstance) -> void:
	item_info_panel.visible = true
	item_info_name_label.text = item.get_item_name()
	item_info_description_label.text = item.get_item_description()

func _on_item_unhover() -> void:
	item_info_panel.visible = false
