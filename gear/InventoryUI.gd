extends Control
class_name InventoryUI

var party_manager := PartyManager
var selected_index: int = 0

@onready var inventory_container: VBoxContainer = $InventoryContainer
@onready var character_name_label: Label = $InventoryContainer/CharacterName
@onready var equipped_list: ItemList = $InventoryContainer/EquippedList
@onready var inventory_list: ItemList = $InventoryContainer/InventoryList
@onready var action_button: Button = $InventoryContainer/ActionButton
@onready var unequip_button: Button = $InventoryContainer/UnequipButton
@onready var next_button: Button = $InventoryContainer/NextButton
@onready var prev_button: Button = $InventoryContainer/PrevButton

@onready var item_info_panel: VBoxContainer = $ItemInfoPanel
@onready var item_name_label: Label = $ItemInfoPanel/ItemName
@onready var item_type_label: Label = $ItemInfoPanel/ItemType
@onready var stats_label: Label = $ItemInfoPanel/StatsLabel
@onready var effects_label: Label = $ItemInfoPanel/EffectsLabel
@onready var modifiers_label: Label = $ItemInfoPanel/ModifiersLabel

func _ready():
	inventory_container.visible = false
	party_manager.connect("member_added", Callable(self, "_on_member_added"))
	SaveManager.connect("party_reloaded", Callable(self, "_on_party_reloaded"))
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	equipped_list.item_selected.connect(_on_euipped_item_selected)
	refresh_lists()

func _on_member_added(character: CharacterInstance, row_i, slot_i):
	if party_manager.members.size() == 1:
		selected_index = 0
		refresh_lists()

func refresh_lists():
	var members = party_manager.members
	if members.size() == 0:
		return

	selected_index = clamp(selected_index, 0, members.size() - 1)
	var player: CharacterInstance = members[selected_index]

	character_name_label.text = player.resource.name

	equipped_list.clear()
	for slot_name in player.equipment.keys():
		var item: ItemInstance = player.equipment[slot_name]
		var display_name = "%s: %s" % [slot_name.capitalize(), item.get_item_name() if item else "<empty>"]
		equipped_list.add_item(display_name)

	inventory_list.clear()
	for item in player.inventory.get_all_items():
		inventory_list.add_item(item.get_item_name())

	action_button.visible = false
	unequip_button.visible = false

func _on_inventory_item_selected(index: int):
	equipped_list.deselect_all()
	unequip_button.visible = false
	var player: CharacterInstance = party_manager.members[selected_index]
	var item: ItemInstance = player.inventory.get_all_items()[index]
	show_item_info(item)
	
	if item is GearInstance:
		action_button.text = "Equip"
		action_button.visible = true
	elif item is ConsumableInstance:
		action_button.text = "Use"
		action_button.visible = true
	else:
		action_button.visible = false
		
func _on_euipped_item_selected(index: int):
	inventory_list.deselect_all()
	action_button.visible = false
	var player: CharacterInstance = party_manager.members[selected_index]

	var slot_names = player.equipment.keys()
	var slot_name = slot_names[index]

	var item: GearInstance = player.equipment[slot_name]
	show_item_info(item)

	if item:
		unequip_button.visible = true
	else:
		unequip_button.visible = false

func _on_action_button_pressed():
	var player: CharacterInstance = party_manager.members[selected_index]
	var selected_inventory_index = inventory_list.get_selected_items()
	if selected_inventory_index.size() == 0:
		return

	var idx = selected_inventory_index[0]
	var item: ItemInstance = player.inventory.get_all_items()[idx]

	if item is GearInstance:
		player.equip_item(item)
	elif item is ConsumableInstance:
		item.use_item(player, item)

	refresh_lists()

func _on_unequip_button_pressed():
	var player: CharacterInstance = party_manager.members[selected_index]
	var idxs = equipped_list.get_selected_items()
	if idxs.size() == 0:
		return

	var slot_name = player.equipment.keys()[idxs[0]]
	var item: GearInstance = player.equipment[slot_name]

	if item:
		player.unequip_slot(slot_name)

	refresh_lists()

func _on_next_button_pressed():
	selected_index = (selected_index + 1) % party_manager.members.size()
	refresh_lists()

func _on_prev_button_pressed():
	selected_index = (selected_index - 1 + party_manager.members.size()) % party_manager.members.size()
	refresh_lists()

func _on_inventory_pressed() -> void:
	inventory_container.visible = not inventory_container.visible
	item_info_panel.visible = false

func show_item_info(item: ItemInstance) -> void:
	if item == null:
		item_info_panel.visible = false
		return

	item_info_panel.visible = true
	item_name_label.text = item.get_item_name()
	item_type_label.text = item.item_type_to_string(item.template.type)

	if item is GearInstance:
		var base_stats = item.get_base_stats()
		var stat_lines: Array[String] = []
		for stat in base_stats.keys():
			if base_stats[stat] != 0:
				stat_lines.append("%s: %d" % [Stats.stat_to_string(stat), base_stats[stat]])
		stats_label.text = "\n".join(stat_lines)
		
		if item.get_all_modifiers().size() > 0:
			var mod_lines: Array[String] = []
			for mod in item.get_all_modifiers():
				mod_lines.append("%s" % mod.get_description())
			modifiers_label.text = "\n".join(mod_lines)
		else:
			modifiers_label.text = ""
	else:
		stats_label.text = ""
	
	if item is ConsumableInstance or item is GearInstance:
		if item.get_all_effects().size() > 0:
			var effect_lines: Array[String] = []
			for e in item.get_all_effects():
				effect_lines.append("%s" % e.get_description())
			effects_label.text = "\n".join(effect_lines)
		else:
			effects_label.text = ""

func _on_party_reloaded():
	refresh_lists()
