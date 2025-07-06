extends Panel

class_name PartyMemberSlot

signal target_clicked(target)

var character_instance: CharacterInstance
var targeting_enabled = false

func bind(character: CharacterInstance) -> void:
	character_instance = character

	#$Portrait.texture = character.resource.portrait
	$MarginContainer/GridContainer/NameContainer/Name.text = character.resource.name
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(character.current_health)
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/MaxHP.text = str(character.max_health)
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/CurrentMP.text = str(character.current_mana)
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/MaxMP.text = str(character.max_mana)

func hide_info():
	var cont = $MarginContainer
	cont.visible = false

func _on_health_changed(new_health: int) -> void:
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(new_health)


func _on_gui_input(event: InputEvent) -> void:
	if not targeting_enabled:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not character_instance:
			print("Invalid party member selected")
			return
			
		print("targeted ", character_instance.resource.name)
		TargetingManager.emit_signal("target_clicked", self)

func disable_slot_targeting():
	targeting_enabled = false

func enable_slot_targeting():
	targeting_enabled = true
