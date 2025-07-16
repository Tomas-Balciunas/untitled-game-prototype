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

func recalculate_stats(character: CharacterInstance):
	attack = base_attack + character.attributes.str * 2
	max_health = base_health + character.attributes.vit * 2
	max_mana = base_mana + character.attributes.iq * 2
	speed = base_speed + character.attributes.spd
