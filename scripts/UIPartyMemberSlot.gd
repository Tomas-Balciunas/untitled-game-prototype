extends Panel

class_name PartyMemberSlot

var character_instance: CharacterInstance

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
