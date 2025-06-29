extends HBoxContainer

var character_instance: CharacterInstance

func bind(character: CharacterInstance) -> void:
	character_instance = character

	#$Portrait.texture = character.resource.portrait
	$Control/PanelContainer/MarginContainer/GridContainer/NameContainer/Name.text = character.resource.name
	$Control/PanelContainer/MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(character.current_health)
	$Control/PanelContainer/MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/MaxHP.text = str(character.max_health)
	$Control/PanelContainer/MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/CurrentMP.text = str(character.current_mana)
	$Control/PanelContainer/MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/MaxMP.text = str(character.max_mana)

func _on_health_changed(new_health: int) -> void:
	$Control/PanelContainer/MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(new_health)
