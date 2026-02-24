extends Panel
class_name InventoryUI

var bound_character: CharacterInstance = null

const ITEM_SLOT = preload("uid://bdksl8u0q4sv0")
const ITEM_TRANSFER_SCENE = preload("uid://csn5t1mi03evw")


@onready var inventory_container: VBoxContainer = $Inventory
@onready var equipped_list: VBoxContainer = $Inventory/EquippedList
@onready var inventory_list: VBoxContainer = $Inventory/InventoryList
@onready var action_button: Button = $Inventory/ActionButton
@onready var transfer_button: Button = $Inventory/TransferButton
@onready var unequip_button: Button = $Inventory/UnequipButton
@onready var item_info_panel: VBoxContainer = $ItemInfoPanel

var _selected_item: ItemInstance = null

func _ready() -> void:
	InventoryBus.request_inventory_refresh.connect(_on_request_inventory_refresh)

func bind_character(character: CharacterInstance) -> void:
	bound_character = character
	refresh_lists()

func refresh_lists() -> void:
	equipped_list.bind_equipped(bound_character, self)

	for child in inventory_list.get_children():
		child.queue_free()
	for item in bound_character.inventory.get_all_items():
		var slot := ITEM_SLOT.instantiate()
		inventory_list.add_child(slot)
		slot.bind(item)
		slot.item_hovered.connect(item_info_panel.show_item_info)
		slot.item_unhovered.connect(item_info_panel.hide_item_info)
		slot.item_selected.connect(_on_inventory_item_selected)

	action_button.visible = false
	unequip_button.visible = false
	transfer_button.visible = false

func _on_inventory_item_selected(item: ItemInstance) -> void:
	unequip_button.visible = false
	_selected_item = item
	
	transfer_button.visible = true
	
	if item is GearInstance:
		action_button.text = "Equip"
		action_button.visible = true
	elif item is Consumable:
		action_button.text = "Use"
		action_button.visible = true
	else:
		action_button.visible = false
		
func _on_equipped_item_selected(item: GearInstance) -> void:
	action_button.visible = false
	_selected_item = item

	if item:
		unequip_button.visible = true
	else:
		unequip_button.visible = false

func _on_action_button_pressed() -> void:
	if not _selected_item:
		push_error("Trying to equip/use null selected item")

	if _selected_item is GearInstance:
		bound_character.equip_item(_selected_item)
	elif _selected_item is Consumable:
		_selected_item.use_item(bound_character)

	refresh_lists()

func _on_unequip_button_pressed() -> void:
	if not _selected_item:
		push_error("Trying to unequip null selected item")

	var slot_name := bound_character.get_slot_name_for_item(_selected_item)
	bound_character.unequip_slot(slot_name)

	refresh_lists()

func cleanup() -> void:
	item_info_panel.hide()
	InventoryBus.inventory_closed.emit()


func _on_transfer_button_pressed() -> void:
	if len(PartyManager.members) <= 1:
		NotificationBus.notification_requested.emit("No allies to transfer an item to!")
	
	var inst := ITEM_TRANSFER_SCENE.instantiate()
	add_child(inst)
	inst.bind(bound_character, _selected_item)
	_selected_item = null

func _on_request_inventory_refresh() -> void:
	refresh_lists()
