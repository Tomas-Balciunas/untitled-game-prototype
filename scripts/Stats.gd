extends Node

class_name Stats

var base_attack: int = 0
var base_health: int = 0
var base_speed: int = 0
var base_mana: int = 0

var attack: int = 0
var current_health: int = 0
var max_health: int = 0
var current_mana: int = 0
var max_mana: int = 0
var speed: int = 0

func recalculate_stats(character: CharacterInstance, fill_hp: bool = false):
	#TODO gotta figure out a way to calc enemy stats due to no classes
	var modifiers = character.job.attribute_modifiers
	attack = base_attack + character.attributes.str * modifiers[Attributes.STR]
	max_health = base_health + character.attributes.vit * modifiers[Attributes.VIT]
	max_mana = base_mana + character.attributes.iq * modifiers[Attributes.IQ]
	speed = base_speed + character.attributes.spd * modifiers[Attributes.SPD]
	
	if fill_hp:
		fill_hp()

func fill_hp():
	current_health = max_health
