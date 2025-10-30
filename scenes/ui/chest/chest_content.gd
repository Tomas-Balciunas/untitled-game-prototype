extends Node

const CHEST_ITEM_SCENE = preload("uid://b7jqf5efs1v46")

@onready var item_info_panel: VBoxContainer = $ItemInfoPanel
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var label: Label = $Label

var items: Array[ItemInstance] = []
var selected_item: ItemInstance = null

func init(chest: Chest) -> void:
	if chest.items.is_empty():
		label.text = "<Chest is empty>"
		return
	
	for item in chest.items:
		var item_instance: ItemInstance = item.instantiate()
		items.append(item_instance)
		var inst := CHEST_ITEM_SCENE.instantiate()
		v_box_container.add_child(inst)
		inst.init(item_instance)
		inst.chest_item_selected.connect(on_item_selected)
	
	on_item_selected(items[0])

func on_item_selected(item: ItemInstance) -> void:
	selected_item = item
	label.text = "Selected item: %s" % item.get_item_name()
	item_info_panel.show_item_info(item)

func _on_close_pressed() -> void:
	queue_free()
