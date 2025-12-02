extends Control
class_name CharacterMenu

@onready var stats_tab: PanelContainer = %StatsUI
@onready var inventory_tab: InventoryUI = %InventoryUI
@onready var effects_tab: PanelContainer = %EffectsUI
@onready var skills_tab: PanelContainer = %SkillsUI
@onready var level_up_tab: Panel = %LevelUpUI
@onready var level_up_button: Button = %LevelUp

@onready var inventory_container: VBoxContainer = %Inventory
@onready var item_info_panel: VBoxContainer = %ItemInfoPanel

@onready var name_label: Label = $Name

var character_instance: CharacterInstance

func bind(character: CharacterInstance) -> void:
	if BattleContext.in_battle:
		return
		
	character_instance = character
	name_label.text = character.resource.name
	stats_tab.bind_character(character_instance)
		
	show_tab("stats")
	
func show_tab(tab: String) -> void:
	if character_instance.unspent_attribute_points <= 0:
		level_up_button.visible = false
	else:
		level_up_button.visible = true
		
	var tabs := {
		"stats": stats_tab,
		"inventory": inventory_tab,
		"effects": effects_tab,
		"skills": skills_tab,
		"levelup": level_up_tab
	}
	
	for key: String in tabs.keys():
		if key == tab:
			tabs[tab].visible = true
			if tabs[tab].has_method("close"):
				tabs[tab].close()
			continue
		tabs[key].visible = false

func _on_inventory_pressed() -> void:
	inventory_tab.bind_character(character_instance)
	show_tab("inventory")


func _on_stats_pressed() -> void:
	stats_tab.bind_character(character_instance)
	show_tab("stats")


func _on_skills_pressed() -> void:
	skills_tab.bind_character(character_instance)
	show_tab("skills")


func _on_effects_pressed() -> void:
	effects_tab.bind_character(character_instance)
	show_tab("effects")


func _on_close_pressed() -> void:
	hide()
	inventory_tab.close()


func _on_talk_pressed() -> void:
	var res := character_instance.resource
	
	if res.interaction_controller and res.interactions:
		res.interaction_controller.handle(res)

func _on_level_up_pressed() -> void:
	level_up_tab.bind_character(character_instance)
	show_tab("levelup")
