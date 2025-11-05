extends Node
class_name Stats

const ATTACK        := "ATTACK"
const HEALTH        := "HEALTH"
const MANA          := "MANA"
const SPEED         := "SPEED"
const DEFENSE       := "DEFENSE"
const MAGIC_POWER   := "MAGIC_POWER"
const DIVINE_POWER  := "DIVINE_POWER"
const MAGIC_DEFENSE := "MAGIC_DEFENSE"
const RESISTANCE    := "RESISTANCE"

enum Stat { ATTACK, HEALTH, MANA, SPEED, DEFENSE, MAGIC_POWER, DIVINE_POWER, MAGIC_DEFENSE, RESISTANCE }

const STATS := {
	ATTACK: 0.0,
	HEALTH: 0.0,
	MANA: 0.0,
	SPEED: 0.0,
	DEFENSE: 0.0,
	MAGIC_POWER: 0.0,
	DIVINE_POWER: 0.0,
	MAGIC_DEFENSE: 0.0,
	RESISTANCE: 0.0
}

var _owner: CharacterInstance = null

var current_health: int = 0
var current_mana: int = 0

var base_stats: Dictionary = {}
var derived_stats: Dictionary = {}
var final_stats: Dictionary = {}
var current_stats: Dictionary = {}

@export var modifiers: Array[StatModifier] = []

func _init(base: Dictionary) -> void:
	for s: String in STATS.keys():
		base_stats[s] = STATS[s]
		derived_stats[s] = STATS[s]
		final_stats[s] = STATS[s]
		current_stats[s] = STATS[s]
		
	for stat: String in base.keys():
		if !STATS.has(stat):
			push_error("Stat %s doesn't exist!" % stat)
			continue
		
		base_stats[stat] = base[stat]

func add_modifier(m: StatModifier) -> void:
	modifiers.append(m)


func remove_modifier(m: StatModifier) -> void:
	modifiers.erase(m)


func recalculate_stats(should_fill_hp: bool = false, should_fill_mp: bool = false) -> void:
	if _owner == null:
		push_error("Stats has no owner! Assign a CharacterInstance to stats.owner")
		return

	var c := _owner
	
	for s: String in STATS.keys():
		if !STATS.has(s):
			push_error("Stat %s doesn't exist!" % s)
			continue
			
		var value: int = base_stats[s]
		derived_stats[s] = value + get_attribute_contribution(s, c) + get_level_contribution(s, c)

	for slot: ItemInstance in c.equipment.values():
		if slot == null:
			continue
		if slot is GearInstance:
			var _base_stats: Dictionary = slot.stats
			
			for stat: String in _base_stats.keys():
				if !STATS.has(stat):
					push_error("Stat %s doesn't exist!" % stat)
					continue
					
				derived_stats[stat] += _base_stats[stat]
		else:
			push_error("Non gear item is equipped: %s" % slot.get_item_name())
#
	var flat_bonus := {}.duplicate()
	var pct_bonus := {}.duplicate()
	
	for s: String in STATS.keys():
		flat_bonus[s] = 0.0
		pct_bonus[s] = 0.0
	
	for mod in modifiers:
		var val := mod.compute_value(c)
		if mod.type == StatModifier.Type.ADDITIVE:
			flat_bonus[stat_enum_to_string(mod.stat)] += val
		elif mod.type == StatModifier.Type.MULTIPLICATIVE:
			pct_bonus[stat_enum_to_string(mod.stat)] += val
			
	for s: String in STATS.keys():
		var value: int = derived_stats[s]
		var flat: float
		var pct: float
		
		if flat_bonus.has(s):
			flat = flat_bonus[s]
			
		if pct_bonus.has(s):
			pct = value * pct_bonus[s]
		
		final_stats[s] = value + flat + pct

	if should_fill_hp:
		fill_hp()
	if should_fill_mp:
		fill_mp()
		
	c.emit_signal("health_changed", current_health, current_health)
	c.emit_signal("mana_changed", current_mana, current_mana)


func fill_hp() -> void:
	current_health = final_stats[HEALTH]

func fill_mp() -> void:
	current_mana = final_stats[MANA]
	
func get_attribute_contribution(stat: String, c: CharacterInstance) -> float:
	var mods: Dictionary = c.job.get_stat_attribute_modifiers(stat)
	
	if modifiers.is_empty():
		return 0.0
	
	var calculated_value: float = 0.0
	
	for attr: String in mods.keys():
		var attribute_value := c.attributes.get_attribute_by_enum(attr)
		var mult: float = mods[attr]
		
		calculated_value += attribute_value * mult
		
	return calculated_value
	
func get_level_contribution(stat: String, c: CharacterInstance) -> float:
	return c.job.get_stat_level_growth(stat) * (c.level - 1) + c.resource.get_stat_level_growth(stat) * (c.level - 1)
	
func get_final_stat(stat: String) -> int:
	if !final_stats.has(stat):
			push_error("Stat %s doesn't exist!" % stat)
			
			return 0
			
	return final_stats[stat]
			
static func stat_to_name(stat: String) -> String:
	match stat:
		ATTACK: return "Attack"
		HEALTH: return "Health"
		SPEED: return "Speed"
		MANA: return "Mana"
		DEFENSE: return "Defense"
		MAGIC_POWER: return "Magic Power"
		DIVINE_POWER: return "Divine Power"
		MAGIC_DEFENSE: return "Magic Defense"
		RESISTANCE: return "Resistance"
		_: return "Unknown"
		
static func stat_enum_to_string(stat: Stat) -> String:
	match stat:
		Stat.ATTACK: return ATTACK
		Stat.HEALTH: return HEALTH
		Stat.MANA: return MANA
		Stat.SPEED: return SPEED
		Stat.DEFENSE: return DEFENSE
		Stat.MAGIC_POWER: return MAGIC_POWER
		Stat.DIVINE_POWER: return DIVINE_POWER
		Stat.MAGIC_DEFENSE: return MAGIC_DEFENSE
		Stat.RESISTANCE: return RESISTANCE
		_: return "Unknown"
