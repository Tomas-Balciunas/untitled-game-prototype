extends Node

const CHEST_ITEM_SCENE = preload("uid://b7jqf5efs1v46")
const CHEST_ITEM_TRANSFER_SELECT = preload("uid://b6obrmkrwcd6e")

@onready var item_info_panel: VBoxContainer = $ItemInfoPanel
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var label: Label = $Label
@onready var members_select: HBoxContainer = $MembersSelect

var items: Array[ItemInstance] = []
var chest: Chest
var selected_item: ItemInstance = null

func init(_chest: Chest) -> void:
	chest = _chest
	
	if chest.items.is_empty():
		members_select.visible = false
		label.text = "<Chest is empty>"
		return
	
	for item in chest.items:
		var item_instance: ItemInstance = item.instantiate()
		items.append(item_instance)
		var inst := CHEST_ITEM_SCENE.instantiate()
		v_box_container.add_child(inst)
		inst.init(item_instance)
		inst.chest_item_selected.connect(on_item_selected)
	
	for member in PartyManager.members:
		var inst := CHEST_ITEM_TRANSFER_SELECT.instantiate()
		members_select.add_child(inst)
		inst.init(member)
		inst.button.pressed.connect(on_character_selected.bind(member))
	
	on_item_selected(items[0])

func on_item_selected(item: ItemInstance) -> void:
	selected_item = item
	label.text = "Selected item: %s" % item.get_item_name()
	item_info_panel.show_item_info(item)
	item_info_panel.visible = true

func on_character_selected(character: CharacterInstance) -> void:
	if !selected_item:
		push_error("Selected item is null in chest!")
	
	if !character.inventory.has_free_slot():
		NotificationBus.notification_requested.emit("%s has no free slots" % character.resource.name)

	character.inventory.add_item(selected_item)
	NotificationBus.notification_requested.emit("%s has received %s" % [character.resource.name, selected_item.get_item_name()])
	remove_item_from_chest(selected_item)
	
func remove_item_from_chest(item: ItemInstance) -> void:
	chest.remove_item(item)
	items.erase(item)
	
	for child in v_box_container.get_children():
		if child.get_item_instance() == item:
			child.queue_free()
			break
	
	if items.is_empty():
		label.text = "<Chest is empty>"
		selected_item = null
		item_info_panel.hide_item_info()
		members_select.visible = false
	else:
		on_item_selected(items[0])

func _on_close_pressed() -> void:
	queue_free()
