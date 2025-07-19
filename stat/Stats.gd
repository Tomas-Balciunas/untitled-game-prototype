extends Node

class_name Stats

var base_attack: int = 0
var base_health: int = 0
var base_speed: int = 0
var base_mana: int = 0

var derived_attack: int = 0
var derived_health: int = 0
var derived_speed: int = 0
var derived_mana: int = 0

var attack: int = 0
var max_health: int = 0
var max_mana: int = 0
var speed: int = 0

var current_health: int = 0
var current_mana: int = 0

@export var modifiers: Array[StatModifier] = []

func add_modifier(m: StatModifier) -> void:
	modifiers.append(m)

func remove_modifier(m: StatModifier) -> void:
	modifiers.erase(m)

func recalculate_stats(character: CharacterInstance, fill_hp: bool = false):
	var attr_mods = character.job.attribute_modifiers

	derived_attack = base_attack + character.attributes.str * attr_mods.get(Attributes.STR, 0)
	derived_health = base_health + character.attributes.vit * attr_mods.get(Attributes.VIT, 0)
	derived_mana   = base_mana   + character.attributes.iq  * attr_mods.get(Attributes.IQ, 0)
	derived_speed  = base_speed  + character.attributes.spd * attr_mods.get(Attributes.SPD, 0)

	var flat_bonus = {
		"attack": 0.0,
		"health": 0.0,
		"mana": 0.0,
		"speed": 0.0
	}
	var pct_bonus = {
		"attack": 0.0,
		"health": 0.0,
		"mana": 0.0,
		"speed": 0.0
	}
	
	for gear in [character.weapon]:
		if not gear:
			continue
		for stat in gear.base_stat_bonuses.keys():
			flat_bonus[stat] += gear.base_stat_bonuses[stat]

	for mod in modifiers:
		var val = mod.compute_value(character)
		if mod.type == StatModifier.Type.ADDITIVE:
			flat_bonus[mod.attribute] += val
		elif mod.type == StatModifier.Type.MULTIPLICATIVE:
			pct_bonus[mod.attribute] += val

	attack     = derived_attack + flat_bonus["attack"] + derived_attack * pct_bonus["attack"]
	max_health = derived_health + flat_bonus["health"] + derived_health * pct_bonus["health"]
	max_mana   = derived_mana   + flat_bonus["mana"]   + derived_mana   * pct_bonus["mana"]
	speed      = derived_speed  + flat_bonus["speed"]  + derived_speed  * pct_bonus["speed"]
	
	if fill_hp:
		fill_hp()

func fill_hp():
	current_health = max_health
