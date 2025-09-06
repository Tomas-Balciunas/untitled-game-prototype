extends Control
class_name CharacterMenu

@onready var stats_tab = $Menu/StatsUI
@onready var inventory_tab = $Menu/InventoryUI
@onready var effects_tab = $Menu/EffectsUI
@onready var skills_tab = $Menu/SkillsUI

@onready var inventory_container: VBoxContainer = $Menu/InventoryUI/Inventory
@onready var item_info_panel: VBoxContainer = $Menu/InventoryUI/ItemInfoPanel

@onready var party_panel = get_tree().get_root().get_node("Main/PartyPanel")
@onready var battle_text_lines = get_tree().get_root().get_node("Main/BattleTextLines")
@onready var menu = $Menu
@onready var name_label = $Menu/Name

var character_instance: CharacterInstance

func bind(character: CharacterInstance) -> void:
	if BattleContext.in_battle:
		return
		
	GameState.current_state = GameState.States.MENU
		
	character_instance = character
	party_panel.disable_party_ui()
	battle_text_lines.disable_battle_text_lines_ui()
	$Menu/Name.text = character.resource.name
	stats_tab.bind_character(character_instance)
	show_tab("stats")
	
func show_tab(tab: String):
	var tabs := {
		"stats": stats_tab,
		"inventory": inventory_tab,
		"effects": effects_tab,
		"skills": skills_tab
	}
	
	for key in tabs.keys():
		if key == tab:
			tabs[tab].visible = true
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
	party_panel.enable_party_ui()
	battle_text_lines.enable_battle_text_lines_ui()
	inventory_tab.close()
	GameState.current_state = GameState.States.IDLE


func _on_talk_pressed() -> void:
	var interaction = character_instance.resource.get_interactions()
	
	if not interaction:
		return
	
	var menu_interaction = interaction.get_dialogue("menu_talk", "random_01")
	ConversationManager.show_dialogue(character_instance.resource.name, menu_interaction["text"])
