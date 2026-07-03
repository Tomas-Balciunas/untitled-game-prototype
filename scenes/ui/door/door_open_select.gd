extends Node
class_name DoorOpenerChoiceInterface

signal close_door_opener_choice

@onready var v_box_container: VBoxContainer = $VBoxContainer

func init() -> void:
	_clear()
	
	for member in PartyManager.members:
		var btn := Button.new()
		btn.text = member.resource.name
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(on_opener_clicked.bind(member))
		v_box_container.add_child(btn)
		
func on_opener_clicked(c: Character) -> void:
	close_door_opener_choice.emit()
	ObjectBus.door_opener_chosen.emit(c)


func _clear() -> void:
	for child: Button in v_box_container.get_children():
		child.queue_free()
