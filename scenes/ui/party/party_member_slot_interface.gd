extends Panel

class_name PartyMemberSlot

@onready var number_display: UISlotNumbers = $NumberDisplay
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var character_instance: CharacterInstance
var targeting_enabled := false

func _ready() -> void:
	CharacterBus.health_changed.connect(_on_health_changed)
	CharacterBus.character_damaged.connect(_on_damaged)
	CharacterBus.character_healed.connect(_on_healed)
	
	BattleBus.ally_turn_started.connect(highlight)
	BattleBus.turn_ended.connect(unhighlight)
	BattleBus.battle_end.connect(unhighlight)
	hide_info()

func bind(character: CharacterInstance) -> void:
	character_instance = character

	#$Portrait.texture = character.resource.portrait
	$MarginContainer/GridContainer/NameContainer/Name.text = character.resource.name
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(character.stats.current_health)
	$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/MaxHP.text = str(character.stats.get_final_stat(Stats.HEALTH))
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/CurrentMP.text = str(character.stats.current_mana)
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/MaxMP.text = str(character.stats.get_final_stat(Stats.MANA))
	
	show_info()
	
func _on_damaged(c: CharacterInstance, amt: int) -> void:
	if character_instance and c == character_instance:
		play_damaged()
		number_display.display_damage(amt)
	
func _on_healed(c: CharacterInstance, amt: int) -> void:
	if character_instance and c == character_instance:
		number_display.display_heal(amt)

func play_damaged() -> void:
	if animation_player.has_animation("damaged"):
		animation_player.play("damaged")

func show_info() -> void:
	$MarginContainer.visible = true

func hide_info() -> void:
	var cont := $MarginContainer
	cont.visible = false

func _on_health_changed(who: CharacterInstance, _old_health: int, _new_health: int) -> void:
	if character_instance == who:
		$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/CurrentHP.text = str(character_instance.stats.current_health)
		$MarginContainer/GridContainer/LabelValueContainer/Values/HPContainer/MaxHP.text = str(character_instance.stats.get_final_stat(Stats.HEALTH))

func _on_mana_changed(_old_mana: int, _new_mana: int) -> void:
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/CurrentMP.text = str(character_instance.stats.current_mana)
	$MarginContainer/GridContainer/LabelValueContainer/Values/MPContainer/MaxMP.text = str(character_instance.stats.get_final_stat(Stats.MANA))

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if BattleContext.in_battle and targeting_enabled:
			if not character_instance:
				print("Invalid party member selected")
				return
				
			print("targeted ", character_instance.resource.name)
			BattleBus.target_selected.emit(character_instance)
		else:
			if not BattleContext.in_battle:
				if not character_instance:
					print("Invalid party member selected")
					return
				CharacterBus.display_character_menu.emit(character_instance)

func disable_slot_targeting() -> void:
	targeting_enabled = false

func enable_slot_targeting() -> void:
	targeting_enabled = true

func _on_mouse_entered() -> void:
	if not targeting_enabled:
		return
	$HoverOverlay.visible = true

func _on_mouse_exited() -> void:
	$HoverOverlay.visible = false

func highlight(battler: CharacterInstance) -> void:
	if !character_instance == battler:
		return
	
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(0.8, 0.8, 0.4), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func unhighlight() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
