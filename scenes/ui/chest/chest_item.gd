extends Node

signal chest_item_selected(item: ItemInstance)

@onready var button: Button = $Button
var item: ItemInstance

func init(_item: ItemInstance) -> void:
	item = _item
	button.text = _item.get_item_name()
	button.pressed.connect(on_item_pressed)

func on_item_pressed() -> void:
	chest_item_selected.emit(item)

func get_item_instance() -> ItemInstance:
	return item
