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


static func get_accuracy(weapon_type: WeaponResource.Type) -> int:
	if not ACCURACY.has(weapon_type):
		push_error("item config: accuracy not found for weapon type")
		return 0
	return ACCURACY[weapon_type]


static func get_stat_range(tier: String, type: Item.ItemType) -> Dictionary:
	if not BASE_STAT_RANGES.has(type):
		push_error("item config: stat range not found for type %s" % type)
		return {}
	var mult := get_tier_multiplier(tier)
	var result: Dictionary = {}
	for stat: Stats.StatRef in BASE_STAT_RANGES[type]:
		var base: Array = BASE_STAT_RANGES[type][stat]
		result[stat] = [base[0] * mult, base[1] * mult]
	return result


static func get_stat_range_weapon(tier: String, type: Item.ItemType, weapon_type: WeaponResource.Type) -> Dictionary:
	if not BASE_STAT_RANGES.has(type) or not BASE_STAT_RANGES[type].has(weapon_type):
		push_error("item config: weapon stat range not found for %s %s" % [tier, weapon_type])
		return {}
	var mult := get_tier_multiplier(tier)
	var result: Dictionary = {}
	for stat: Stats.StatRef in BASE_STAT_RANGES[type][weapon_type]:
		var base: Array = BASE_STAT_RANGES[type][weapon_type][stat]
		result[stat] = [base[0] * mult, base[1] * mult]
	return result


static func get_applicable_modifiers(type: Item.ItemType) -> Array[Stats.StatRef]:
	match type:
		Item.ItemType.WEAPON: return [Stats.StatRef.ATTACK, Stats.StatRef.MAGIC_POWER, Stats.StatRef.DIVINE_POWER]
		Item.ItemType.CHEST:  return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
		Item.ItemType.HELMET: return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
		Item.ItemType.BOOTS:  return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE, Stats.StatRef.EVASION]
		Item.ItemType.GLOVES: return [Stats.StatRef.HEALTH, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE, Stats.StatRef.ACCURACY]
		Item.ItemType.RING:   return [Stats.StatRef.SP, Stats.StatRef.DEFENSE, Stats.StatRef.MAGIC_DEFENSE]
		Item.ItemType.AMULET: return [Stats.StatRef.HEALTH, Stats.StatRef.MANA, Stats.StatRef.SP]
	push_error("item config: applicable modifiers not found for type %s" % type)
	return []


const TIER_DATA: Dictionary = {
	"tier_1": { "name": "Crude", "mult": 1.0, "max_modifiers": 1 },
	"tier_2": { "name": "Worn",  "mult": 1.5, "max_modifiers": 2 },
}

const ACCURACY: Dictionary = {
	WeaponResource.Type.SWORD: 5,
	WeaponResource.Type.AXE:   8,
}

const BASE_STAT_RANGES: Dictionary = {
	Item.ItemType.WEAPON: {
		WeaponResource.Type.SWORD: { Stats.StatRef.ATTACK: [5, 8] },
		WeaponResource.Type.AXE:   { Stats.StatRef.ATTACK: [8, 12] },
	},
	Item.ItemType.CHEST: {
		Stats.StatRef.HEALTH:       [1, 3],
		Stats.StatRef.DEFENSE:      [1, 3],
		Stats.StatRef.MAGIC_DEFENSE:[1, 1],
	},
	Item.ItemType.HELMET: {
		Stats.StatRef.DEFENSE: [1, 3],
	},
	Item.ItemType.BOOTS: {
		Stats.StatRef.DEFENSE:  [1, 3],
		Stats.StatRef.SPEED:    [1, 2],
		Stats.StatRef.EVASION:  [1, 2],
	},
	Item.ItemType.GLOVES: {
		Stats.StatRef.DEFENSE:   [1, 3],
		Stats.StatRef.ACCURACY:  [1, 2],
	},
	Item.ItemType.RING: {
		Stats.StatRef.MAGIC_DEFENSE: [1, 3],
	},
	Item.ItemType.AMULET: {
		Stats.StatRef.MAGIC_DEFENSE: [1, 3],
	},
}
