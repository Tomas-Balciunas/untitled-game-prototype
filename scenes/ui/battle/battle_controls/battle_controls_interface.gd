extends Control


var current_battler: Character = null

@onready var attack_button: Button = %AttackButton
@onready var defend_button: Button = %DefendButton
@onready var skill_button: Button = %SkillButton
@onready var item_button: Button = %ItemButton
@onready var flee_button: Button = %FleeButton
@onready var end_turn_button: Button = %EndTurnButton

@onready var skill_popup := $Skill
@onready var skill_list_container := $Skill/ScrollContainer/SkillListContainer
const SKILL_ENTRY = preload("uid://by0xll5nd2ejj")

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

@onready var ap_container: HBoxContainer = $ap_container
const AP_SCENE = preload("uid://dlnv4bs0wadg2")


func _ready() -> void:
	ap_container.visible = false
	BattleBus.battle_start.connect(_on_battle_start)
	BattleBus.battle_end.connect(_on_battle_end)
	
	BattleBus.queue_processed.connect(_on_queue_processed)
	
	BattleBus.ally_turn_started.connect(_on_ally_turn_started)
	BattleBus.turn_ended.connect(_on_turn_ended)
	BattleBus.action_points_changed.connect(on_action_points_changed)

func _on_queue_processed(queue: Array[Character]) -> void:
	for child in v_box_container_2.get_children():
		child.queue_free()
	var index := 1
	var label2 := Label.new()
	label2.text = "Current. %s av: %s" % [BattleContext.manager.current_battler.resource.name if current_battler else "", BattleContext.manager.current_battler.action_value if current_battler else ""]
	v_box_container_2.add_child(label2)
	for c: Character in queue:
		var label := Label.new()
		label.text = "%s. %s - action val.: %s" % [index if index > 1 else "Next", c.resource.name, c.action_value]
		index += 1
		v_box_container_2.add_child(label)


func _on_battle_start() -> void:
	hide()


func _on_battle_end() -> void:
	hide()


func _on_ally_turn_started(battler: Character) -> void:
	ap_container.visible = true
	current_battler = battler
	_populate_skill_list()
	_populate_item_list()
	skill_popup.visible = false
	item_popup.visible = false
	highlight_action("attack")
	show()


func _on_turn_ended() -> void:
	ap_container.visible = false
	for child:TextureRect in ap_container.get_children():
		child.queue_free()
	
	hide()


func _on_defend_button_pressed() -> void:
	BattleBus.action_selected.emit(GuardAction.new())

func _on_attack_button_pressed() -> void:
	BattleBus.action_selected.emit(BasicAttack.new())
	skill_popup.visible = false
	item_popup.visible = false

func _on_flee_button_pressed() -> void:
	BattleBus.action_selected.emit(FleeAction.new())

func _on_end_turn_button_pressed() -> void:
	BattleBus.control_selected.emit(BattleBus.END_TURN)

func _on_skill_selected(skill: Skill) -> void:
	BattleBus.action_selected.emit(SkillAction.new(skill))
	skill_popup.visible = false

func _on_item_selected(item: Consumable) -> void:
	BattleBus.action_selected.emit(ItemAction.new(item))
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
		if not item is Consumable:
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

	
	for skill: Skill in current_battler.learnt_skills:
		var entry: SkillEntryInterface = SKILL_ENTRY.instantiate()
		skill_list_container.add_child(entry)
		
		var modified_skill: Skill = entry.bind(skill, current_battler)
		entry.pressed.connect(_on_skill_selected.bind(modified_skill))
		entry.mouse_entered.connect(_on_skill_hover.bind(modified_skill))
		entry.mouse_exited.connect(_on_skill_unhover)
		


func _on_skill_hover(skill: Skill) -> void:
	skill_info_panel.visible = true
	skill_info_name_label.text = skill.name
	skill_info_cost_label.text = "MP: %s, SP: %s" % [skill.cost.mana, skill.cost.sp]
	skill_info_description_label.text = skill.description

func _on_skill_unhover() -> void:
	skill_info_panel.visible = false
	
func _on_item_hover(item: Consumable) -> void:
	item_info_panel.visible = true
	item_info_name_label.text = item.get_item_name()
	item_info_description_label.text = item.get_item_description()

func _on_item_unhover() -> void:
	item_info_panel.visible = false

func on_action_points_changed(ap_points: int) -> void:
	for child: TextureRect in ap_container.get_children():
		child.queue_free()
	
	for i in range(ap_points):
		var ap: TextureRect = AP_SCENE.instantiate()
		ap_container.add_child(ap)
