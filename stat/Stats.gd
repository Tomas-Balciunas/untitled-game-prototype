extends Node

class_name Stats

enum Stat {
	ATTACK,
	HEALTH,
	MANA,
	SPEED,
	DEFENSE,
	MAGIC_POWER,
	DIVINE_POWER,
	MAGIC_DEFENSE,
	RESISTANCE,
}

var base_attack: int = 0
var base_health: int = 0
var base_speed: int = 0
var base_mana: int = 0
var base_defense: int = 0
var base_magic_power: int = 0
var base_divine_power: int = 0
var base_magic_defense: int = 0
var base_resistance: int = 0

var derived_attack: int = 0
var derived_health: int = 0
var derived_speed: int = 0
var derived_mana: int = 0
var derived_defense: int = 0
var derived_magic_power: int = 0
var derived_divine_power: int = 0
var derived_magic_defense: int = 0
var derived_resistance: int = 0

var attack: int = 0
var max_health: int = 0
var max_mana: int = 0
var speed: int = 0
var defense: int = 0
var magic_power: int = 0
var divine_power: int = 0
var magic_defense: int = 0
var resistance: int = 0

var current_health: int = 0
var current_mana: int = 0

@export var modifiers: Array[StatModifier] = []


func add_modifier(m: StatModifier) -> void:
	modifiers.append(m)


func remove_modifier(m: StatModifier) -> void:
	modifiers.erase(m)


func recalculate_stats(character: CharacterInstance, should_fill_hp: bool = false, should_fill_mp: bool = false):
	var attr_mods = character.job.attribute_modifiers
# TODO: improve attr scaling to accommodate several sources of scaling for a single stat and custom scaling for characters
	derived_attack       = base_attack       + character.attributes.str * attr_mods.get(Attributes.STR, 1)
	derived_health       = base_health       + character.attributes.vit * attr_mods.get(Attributes.VIT, 1)
	derived_mana         = base_mana         + character.attributes.iq  * attr_mods.get(Attributes.IQ, 1)
	derived_speed        = base_speed        + character.attributes.spd * attr_mods.get(Attributes.SPD, 1)
	derived_defense      = base_defense      + character.attributes.vit * attr_mods.get(Attributes.VIT, 1)
	derived_magic_power  = base_magic_power  + character.attributes.iq  * attr_mods.get(Attributes.IQ, 1)
	derived_divine_power = base_divine_power + character.attributes.pie * attr_mods.get(Attributes.PIE, 1)
	derived_magic_defense= base_magic_defense+ character.attributes.vit  * attr_mods.get(Attributes.VIT, 1)
	derived_resistance   = base_resistance   + character.attributes.pie * attr_mods.get(Attributes.PIE, 1)

	var flat_bonus = {
		Stat.ATTACK: 0.0,
		Stat.HEALTH: 0.0,
		Stat.MANA: 0.0,
		Stat.SPEED: 0.0,
		Stat.DEFENSE: 0.0,
		Stat.MAGIC_POWER: 0.0,
		Stat.DIVINE_POWER: 0.0,
		Stat.MAGIC_DEFENSE: 0.0,
		Stat.RESISTANCE: 0.0,
	}
	var pct_bonus = {
		Stat.ATTACK: 0.0,
		Stat.HEALTH: 0.0,
		Stat.MANA: 0.0,
		Stat.SPEED: 0.0,
		Stat.DEFENSE: 0.0,
		Stat.MAGIC_POWER: 0.0,
		Stat.DIVINE_POWER: 0.0,
		Stat.MAGIC_DEFENSE: 0.0,
		Stat.RESISTANCE: 0.0,
	}
	
	for mod in modifiers:
		var val = mod.compute_value(character)
		if mod.type == StatModifier.Type.ADDITIVE:
			flat_bonus[mod.attribute] += val
		elif mod.type == StatModifier.Type.MULTIPLICATIVE:
			pct_bonus[mod.attribute] += val

	attack       = derived_attack       + flat_bonus[Stat.ATTACK]       + derived_attack       * pct_bonus[Stat.ATTACK]
	max_health   = derived_health       + flat_bonus[Stat.HEALTH]       + derived_health       * pct_bonus[Stat.HEALTH]
	max_mana     = derived_mana         + flat_bonus[Stat.MANA]         + derived_mana         * pct_bonus[Stat.MANA]
	speed        = derived_speed        + flat_bonus[Stat.SPEED]        + derived_speed        * pct_bonus[Stat.SPEED]
	defense      = derived_defense      + flat_bonus[Stat.DEFENSE]      + derived_defense      * pct_bonus[Stat.DEFENSE]
	magic_power  = derived_magic_power  + flat_bonus[Stat.MAGIC_POWER]  + derived_magic_power  * pct_bonus[Stat.MAGIC_POWER]
	divine_power = derived_divine_power + flat_bonus[Stat.DIVINE_POWER] + derived_divine_power * pct_bonus[Stat.DIVINE_POWER]
	magic_defense= derived_magic_defense+ flat_bonus[Stat.MAGIC_DEFENSE]+ derived_magic_defense* pct_bonus[Stat.MAGIC_POWER]
	resistance   = derived_resistance   + flat_bonus[Stat.RESISTANCE]   + derived_resistance   * pct_bonus[Stat.RESISTANCE]

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
