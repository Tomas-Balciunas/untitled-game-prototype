extends RefCounted
class_name ItemConfig


static func get_item_name(tier: String) -> String:
	if not TIER_DATA.has(tier):
		push_error("item config: unknown tier %s" % tier)
		return ""
	return TIER_DATA[tier]["name"]


static func get_max_modifiers(tier: String) -> int:
	if not TIER_DATA.has(tier):
		return 0
	return TIER_DATA[tier]["max_modifiers"]


static func get_tier_multiplier(tier: String) -> float:
	if not TIER_DATA.has(tier):
		push_error("item config: unknown tier %s" % tier)
		return 1.0
	return TIER_DATA[tier]["mult"]


static func get_accuracy(weapon_type: ItemTypes.WeaponType) -> int:
	if not ACCURACY.has(weapon_type):
		push_error("item config: accuracy not found for weapon type")
		return 0
	return ACCURACY[weapon_type]


static func get_stat_range(tier: String, type: ItemTypes.GearType) -> Dictionary:
	if not BASE_STAT_RANGES.has(type):
		push_error("item config: stat range not found for type %s" % type)
		return {}
	var mult := get_tier_multiplier(tier)
	var result: Dictionary = {}
	for stat: Stats.StatRef in BASE_STAT_RANGES[type]:
		var base: Array = BASE_STAT_RANGES[type][stat]
		result[stat] = [base[0] * mult, base[1] * mult]
	return result


static func get_stat_range_weapon(tier: String, type: ItemTypes.GearType, weapon_type: ItemTypes.WeaponType) -> Dictionary:
	if not BASE_STAT_RANGES.has(type) or not BASE_STAT_RANGES[type].has(weapon_type):
		push_error("item config: weapon stat range not found for %s %s" % [tier, weapon_type])
		return {}
	var mult := get_tier_multiplier(tier)
	var result: Dictionary = {}
	for stat: Stats.StatRef in BASE_STAT_RANGES[type][weapon_type]:
		var base: Array = BASE_STAT_RANGES[type][weapon_type][stat]
		result[stat] = [base[0] * mult, base[1] * mult]
	return result


static func get_applicable_modifiers(type: ItemTypes.GearType) -> Array[Stats.StatRef]:
	match type:
		ItemTypes.GearType.WEAPON: return [Stats.StatRef.ATTACK, Stats.StatRef.MAGIC_POWER, Stats.StatRef.DIVINE_POWER]
		ItemTypes.GearType.CHEST:  return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
		ItemTypes.GearType.HELMET: return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
		ItemTypes.GearType.BOOTS:  return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE, Stats.StatRef.EVASION]
		ItemTypes.GearType.GLOVES: return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE, Stats.StatRef.ACCURACY]
		ItemTypes.GearType.RING:   return [Stats.StatRef.SP, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
		ItemTypes.GearType.AMULET: return [Stats.StatRef.HEALTH, Stats.StatRef.MANA, Stats.StatRef.SP]
	push_error("item config: applicable modifiers not found for type %s" % type)
	return []


const TIER_DATA: Dictionary = {
	"tier_1": { "name": "Crude", "mult": 1.0, "max_modifiers": 1 },
	"tier_2": { "name": "Worn",  "mult": 1.5, "max_modifiers": 2 },
}

const ACCURACY: Dictionary = {
	ItemTypes.WeaponType.SWORD: 5,
	ItemTypes.WeaponType.AXE:   8,
}

const BASE_STAT_RANGES: Dictionary = {
	ItemTypes.GearType.WEAPON: {
		ItemTypes.WeaponType.SWORD: { Stats.StatRef.ATTACK: [5, 8] },
		ItemTypes.WeaponType.AXE:   { Stats.StatRef.ATTACK: [8, 12] },
	},
	ItemTypes.GearType.CHEST: {
		Stats.StatRef.HEALTH:       [1, 3],
		Stats.StatRef.DEFENSE:      [1, 3],
		Stats.StatRef.MAGIC_DEFENSE:[1, 1],
	},
	ItemTypes.GearType.HELMET: {
		Stats.StatRef.DEFENSE: [1, 3],
	},
	ItemTypes.GearType.BOOTS: {
		Stats.StatRef.DEFENSE:  [1, 3],
		Stats.StatRef.SPEED:    [1, 2],
		Stats.StatRef.EVASION:  [1, 2],
	},
	ItemTypes.GearType.GLOVES: {
		Stats.StatRef.DEFENSE:   [1, 3],
		Stats.StatRef.ACCURACY:  [1, 2],
	},
	ItemTypes.GearType.RING: {
		Stats.StatRef.MAGIC_DEFENSE: [1, 3],
	},
	ItemTypes.GearType.AMULET: {
		Stats.StatRef.MAGIC_DEFENSE: [1, 3],
	},
}
