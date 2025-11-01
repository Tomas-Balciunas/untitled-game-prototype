extends Control

signal item_hovered(item: ItemInstance)
signal item_unhovered()
signal equipped_item_selected(item: ItemInstance)

var item: ItemInstance = null

func _ready() -> void:
	self.connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	self.connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	self.connect("gui_input", Callable(self, "_on_gui_input"))

func bind(item_instance: ItemInstance) -> void:
	item = item_instance
	
	if not item:
		$Container/Value.text = "<empty>"
		return
		
	$Container/Value.text = item.get_item_name()

func _on_mouse_entered() -> void:
	if item:
		emit_signal("item_hovered", item)
		
func _on_mouse_exited() -> void:
	emit_signal("item_unhovered")

func _on_gui_input(event: InputEvent) -> void:
	if item:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("equipped_item_selected", item)
