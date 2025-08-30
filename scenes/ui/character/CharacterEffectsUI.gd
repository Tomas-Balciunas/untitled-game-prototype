extends Node

@onready var effects_container = $Effects
const EffectLabel = preload("res://scenes/ui/character/EffectLabel.tscn")

func bind_character(character: CharacterInstance):
	clear_effects()
	for effect in character.effects:
		add_effect(effect)

func clear_effects():
	for child in effects_container.get_children():
		child.queue_free()

func add_effect(effect: Effect):
	var label = EffectLabel.instantiate()
	label.text = "%s: %s" % [effect._get_name(), effect.get_description()]
	effects_container.add_child(label)
