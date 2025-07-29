extends Panel

class_name PartyMemberSlot

signal target_clicked(target)

var character_instance: CharacterInstance
var targeting_enabled = false

func bind(character: CharacterInstance) -> void:
	character_instance = character

	#$Portrait.texture = character.resource.portrait
	$MarginContainer/GridContainer/NameContainer/Name.text = character.resource.name
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(character.stats.current_health)
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/MaxHP.text = str(character.stats.max_health)
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/CurrentMP.text = str(character.stats.current_mana)
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/MaxMP.text = str(character.stats.max_mana)

func hide_info():
	var cont = $MarginContainer
	cont.visible = false

func _on_health_changed(_old_health: int, new_health: int) -> void:
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(new_health)

func _on_mana_changed(_old_mana: int, new_mana: int) -> void:
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/CurrentMP.text = str(new_mana)

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

func _on_mouse_entered() -> void:
	if not targeting_enabled:
		return
	$HoverOverlay.visible = true

func _on_mouse_exited() -> void:
	$HoverOverlay.visible = false

func highlight():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.8, 0.8, 0.4), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func unhighlight():
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
