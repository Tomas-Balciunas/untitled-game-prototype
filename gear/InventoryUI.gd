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

func _ready():
	inventory_container.visible = false
	party_manager.connect("member_added", Callable(self, "_on_member_added"))
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
		var item: Item = player.equipment[slot_name]
		var display_name = "%s: %s" % [slot_name.capitalize(), item.name if item else "-"]
		equipped_list.add_item(display_name)

	inventory_list.clear()
	for item in player.inventory.get_all_items():
		inventory_list.add_item(item.name)

	action_button.visible = false
	unequip_button.visible = false

func _on_inventory_item_selected(index: int):
	var player: CharacterInstance = party_manager.members[selected_index]
	var item: Item = player.inventory.get_all_items()[index]
	
	if item is Gear:
		action_button.text = "Equip"
		action_button.visible = true
	elif item is ConsumableItem:
		action_button.text = "Use"
		action_button.visible = true
	else:
		action_button.visible = false
		
func _on_euipped_item_selected(index: int):
	var player: CharacterInstance = party_manager.members[selected_index]

	var slot_names = player.equipment.keys()
	var slot_name = slot_names[index]

	var item: Gear = player.equipment[slot_name]

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
	var item: Item = player.inventory.get_all_items()[idx]

	if item is Gear:
		player.equip_item(item)
	elif item is ConsumableItem:
		item.use_item(player, item)

	refresh_lists()

func _on_unequip_button_pressed():
	var player: CharacterInstance = party_manager.members[selected_index]
	var idxs = equipped_list.get_selected_items()
	if idxs.size() == 0:
		return

	var slot_name = player.equipment.keys()[idxs[0]]
	var item: Gear = player.equipment[slot_name]

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
