extends Node

const EFFECT_LABEL = preload("uid://buyertqp85xfq")

@onready var effects_container := $Effects


func bind_character(character: CharacterInstance) -> void:
	clear_effects()
	for effect: Effect in character.effects:
		add_effect(effect)

func clear_effects() -> void:
	for child in effects_container.get_children():
		child.queue_free()

func add_effect(effect: Effect) -> void:
	var label := EFFECT_LABEL.instantiate()
	label.text = "%s: %s" % [effect._get_name(), effect.get_description()]
	effects_container.add_child(label)
