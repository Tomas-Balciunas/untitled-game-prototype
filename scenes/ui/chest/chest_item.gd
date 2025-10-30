extends Node

signal chest_item_selected(item: ItemInstance)

@onready var button: Button = $Button

func init(item: ItemInstance) -> void:
	button.text = item.get_item_name()
	button.pressed.connect(on_item_pressed.bind(item))

func on_item_pressed(item: ItemInstance) -> void:
	chest_item_selected.emit(item)
