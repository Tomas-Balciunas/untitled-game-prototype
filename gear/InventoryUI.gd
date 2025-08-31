extends Panel
class_name InventoryUI

var bound_character: CharacterInstance = null

const item_slot = preload("res://gear/ItemSlot.tscn")

@onready var inventory_container: VBoxContainer = $Inventory
@onready var equipped_list: VBoxContainer = $Inventory/EquippedList
@onready var inventory_list: VBoxContainer = $Inventory/InventoryList
@onready var action_button: Button = $Inventory/ActionButton
@onready var unequip_button: Button = $Inventory/UnequipButton

@onready var item_info_panel: VBoxContainer = $ItemInfoPanel
@onready var item_name_label: Label = $ItemInfoPanel/ItemName
@onready var item_type_label: Label = $ItemInfoPanel/ItemType
@onready var stats_label: Label = $ItemInfoPanel/StatsLabel
@onready var effects_label: Label = $ItemInfoPanel/EffectsLabel
@onready var modifiers_label: Label = $ItemInfoPanel/ModifiersLabel

var _selected_item: ItemInstance = null

func bind_character(character: CharacterInstance):
	bound_character = character
	refresh_lists()

func refresh_lists():
	equipped_list.bind_equipped(bound_character, self)

	for child in inventory_list.get_children():
		child.queue_free()
	for item in bound_character.inventory.get_all_items():
		var slot = item_slot.instantiate()
		inventory_list.add_child(slot)
		slot.bind(item)
		slot.item_hovered.connect(show_item_info)
		slot.item_unhovered.connect(hide_item_info)
		slot.item_selected.connect(_on_inventory_item_selected)

	action_button.visible = false
	unequip_button.visible = false

func _on_inventory_item_selected(item: ItemInstance):
	unequip_button.visible = false
	_selected_item = item
	
	if item is GearInstance:
		action_button.text = "Equip"
		action_button.visible = true
	elif item is ConsumableInstance:
		action_button.text = "Use"
		action_button.visible = true
	else:
		action_button.visible = false
		
func _on_equipped_item_selected(item: GearInstance):
	action_button.visible = false
	_selected_item = item

	if item:
		unequip_button.visible = true
	else:
		unequip_button.visible = false

func _on_action_button_pressed():
	if not _selected_item:
		push_error("Trying to equip/use null selected item")

	if _selected_item is GearInstance:
		bound_character.equip_item(_selected_item)
	elif _selected_item is ConsumableInstance:
		_selected_item.use_item(bound_character, _selected_item)

	refresh_lists()

func _on_unequip_button_pressed():
	if not _selected_item:
		push_error("Trying to unequip null selected item")

	var slot_name = bound_character.get_slot_name_for_item(_selected_item)
	bound_character.unequip_slot(slot_name)

	refresh_lists()

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
			
func hide_item_info():
	item_info_panel.visible = false

func close():
	item_info_panel.hide()
