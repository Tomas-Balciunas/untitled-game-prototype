extends Node

class_name ItemSlot

signal item_hovered(item: ItemInstance)
signal item_unhovered()
signal item_selected(item: ItemInstance)

@onready var item_name: Label = $Container/Name

var item: ItemInstance = null

func bind(item_instance: ItemInstance) -> void:
	item = item_instance
	item_name.text = item.get_item_name()


func _on_mouse_entered() -> void:
	emit_signal("item_hovered", item)


func _on_mouse_exited() -> void:
	emit_signal("item_unhovered")


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("item_selected", item)
