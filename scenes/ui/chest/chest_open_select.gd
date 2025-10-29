extends Node

@onready var v_box_container: VBoxContainer = $VBoxContainer

signal chest_opener_chosen(c: CharacterInstance)

func init() -> void:
	for member in PartyManager.members:
		var btn := Button.new()
		btn.text = member.resource.name
		btn.pressed.connect(on_opener_clicked.bind(member))
		v_box_container.add_child(btn)
		
func on_opener_clicked(c: CharacterInstance) -> void:
	chest_opener_chosen.emit(c)
	queue_free()
