extends Panel
class_name ChestContentInterface

signal close_chest_content

const CHEST_ITEM_SCENE = preload("uid://b7jqf5efs1v46")
const CHEST_ITEM_TRANSFER_SELECT = preload("uid://b6obrmkrwcd6e")

@onready var item_info_panel: VBoxContainer = $ItemInfoPanel
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var label: Label = $Label
@onready var members_select: HBoxContainer = $MembersSelect

var items: Array[ItemInstance] = []
var chest: Chest
var selected_item: ItemInstance = null

func _ready() -> void:
	InteractableBus.interactable_area_left.connect(on_interactable_area_left)

func init(_chest: Chest) -> void:
	_clear()
	chest = _chest
	
	if chest.items.is_empty():
		members_select.visible = false
		label.text = "<Chest is empty>"
		return
	
	members_select.visible = true
	
	for item in chest.items:
		items.append(item)
		var inst := CHEST_ITEM_SCENE.instantiate()
		v_box_container.add_child(inst)
		inst.init(item)
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

	if remove_item_from_chest(selected_item):
		character.inventory.add_item(selected_item)
		NotificationBus.notification_requested.emit("%s has received %s" % [character.resource.name, selected_item.get_item_name()])
		remove_item(selected_item)
	else:
		push_error("Item was not removed from chest")
	
func remove_item_from_chest(item: ItemInstance) -> bool:
	var success: bool = chest.remove_item(item)
	
	if not success:
		return false
	
	ChestBus.chest_state_changed.emit(chest)
	
	return true


func remove_item(item: ItemInstance) -> void:
	for child in v_box_container.get_children():
		if child.get_item_instance() == item:
			child.queue_free()
			break
	
	items.erase(item)
	
	if items.is_empty():
		label.text = "<Chest is empty>"
		selected_item = null
		item_info_panel.hide_item_info()
		members_select.visible = false
	else:
		on_item_selected(items[0])


func _on_close_pressed() -> void:
	close_chest_content.emit()

func on_interactable_area_left(interactable: Interactable) -> void:
	if interactable is ChestInteractable:
		close_chest_content.emit()


func _clear() -> void:
	for child in v_box_container.get_children():
		child.queue_free()
	
	for child in members_select.get_children():
		child.queue_free()
