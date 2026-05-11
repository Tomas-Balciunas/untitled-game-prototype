extends Node

signal chest_item_selected(item: Item)

@onready var button: Button = $Button
var item: Item

func init(_item: Item) -> void:
	item = _item
	button.text = _item.get_item_name()
	button.pressed.connect(on_item_pressed)

func on_item_pressed() -> void:
	chest_item_selected.emit(item)

func get_item_instance() -> Item:
	return item
