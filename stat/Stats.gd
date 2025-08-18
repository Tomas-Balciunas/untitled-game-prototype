extends Node

class_name Stats

var base_attack: int = 0
var base_health: int = 0
var base_speed: int = 0
var base_mana: int = 0
var base_defense: int = 0

var derived_attack: int = 0
var derived_health: int = 0
var derived_speed: int = 0
var derived_mana: int = 0
var derived_defense: int = 0

var attack: int = 0
var max_health: int = 0
var max_mana: int = 0
var speed: int = 0
var defense: int = 0

var current_health: int = 0
var current_mana: int = 0

@export var modifiers: Array[StatModifier] = []

func add_modifier(m: StatModifier) -> void:
	modifiers.append(m)

func remove_modifier(m: StatModifier) -> void:
	modifiers.erase(m)

func recalculate_stats(character: CharacterInstance, should_fill_hp: bool = false, should_fill_mp: bool = false):
	var attr_mods = character.job.attribute_modifiers

	derived_attack = base_attack + character.attributes.str * attr_mods.get(Attributes.STR, 1)
	derived_health = base_health + character.attributes.vit * attr_mods.get(Attributes.VIT, 1)
	derived_mana   = base_mana   + character.attributes.iq  * attr_mods.get(Attributes.IQ, 1)
	derived_speed  = base_speed  + character.attributes.spd * attr_mods.get(Attributes.SPD, 1)
	derived_defense = base_defense + character.attributes.vit * attr_mods.get(Attributes.VIT, 1)

	var flat_bonus = {
		"attack": 0.0,
		"health": 0.0,
		"mana": 0.0,
		"speed": 0.0,
		"defense": 0.0
	}
	var pct_bonus = {
		"attack": 0.0,
		"health": 0.0,
		"mana": 0.0,
		"speed": 0.0,
		"defense": 0.0
	}
	
	for gear in character.equipment:
		if not character.equipment[gear]:
			continue
		if "base_stat_bonuses" in character.equipment[gear]:
			for stat in character.equipment[gear].base_stat_bonuses.keys():
				flat_bonus[stat] += character.equipment[gear].base_stat_bonuses[stat]

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
	defense      = derived_defense  + flat_bonus["defense"]  + derived_defense  * pct_bonus["defense"]
	
	if should_fill_hp:
		fill_hp()
		
	if should_fill_mp:
		fill_mp()
		
	character.emit_signal("health_changed", current_health, current_health)
	character.emit_signal("mana_changed", current_mana, current_mana)

func fill_hp():
	current_health = max_health

func fill_mp():
	current_mana = max_mana
