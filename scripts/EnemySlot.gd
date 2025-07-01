extends Node3D

var character_instance: CharacterInstance

func bind(character: CharacterInstance):
	character_instance = character
	#if character.resource.portrait:
		#$Portrait.texture = character.resource.portrait
	$NameLabel.text = character.resource.name

func _ready():
	connect("mouse_entered", Callable(self, "_on_hover"))
	connect("gui_input", Callable(self, "_on_gui_input"))

func _on_hover():
	if character_instance:
		$NameLabel.add_theme_color_override("font_color", Color.RED)

func _on_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if character_instance and character_instance.current_hp > 0:
			get_tree().root.get_node("Arena/BattleManager")._on_enemy_target_selected(character_instance)

func unhover():
	$NameLabel.add_theme_color_override("font_color", Color.WHITE)

func clear():
	character_instance = null
	unhover()
	#$Portrait.texture = null
	$NameLabel.text = ""
