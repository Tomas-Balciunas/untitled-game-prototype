extends RefCounted
class_name ItemConfig

static func get_item_name(tier: String) -> String:
	if not ITEM_NAME.has(tier):
		push_error("item config name not found for %s" % tier)
		return ""
	
	return ITEM_NAME[tier]


static func get_max_modifiers(tier: String) -> int:
	if MAX_MODIFIERS.has(tier):
		return MAX_MODIFIERS[tier]
	
	return 0


static func get_accuracy(weapon_type: WeaponResource.Type) -> int:
	if not ACCURACY.has(weapon_type):
		push_error("item config error accuracy not found")
		return 0
	
	return ACCURACY[weapon_type]


static func get_stat_range(tier: String, type: Item.ItemType) -> Dictionary:
	if not STAT_RANGE.has(tier):
		push_error("item config error stat range not found")
		return {}
	
	if not STAT_RANGE[tier].has(type):
		push_error("item config error stat range not found")
		return {}
	
	return STAT_RANGE[tier][type]


static func get_stat_range_weapon(tier: String, type: Item.ItemType, weapon_type: WeaponResource.Type) -> Dictionary:
	if not STAT_RANGE.has(tier):
		push_error("item config error stat range tier not found: %s %s" % [tier, weapon_type])
		return {}
	
	if not STAT_RANGE[tier].has(type):
		push_error("item config error stat range type not found: %s %s" % [tier, weapon_type])
		return {}
	
	if not STAT_RANGE[tier][type].has(weapon_type):
		push_error("item config error stat range weapon type not found: %s %s" % [tier, weapon_type])
		return {}
	
	return STAT_RANGE[tier][type][weapon_type]

const ITEM_NAME: Dictionary = {
	"tier_1": "Crude",
	"tier_2": "Worn"
}

const ACCURACY: Dictionary = {
	WeaponResource.Type.SWORD: 5,
	WeaponResource.Type.AXE: 8
}

const MAX_MODIFIERS: Dictionary = {
	"tier_1": 1,
	"tier_2": 2
}

const STAT_RANGE: Dictionary = {
	"tier_1": {
		Item.ItemType.WEAPON: {
			WeaponResource.Type.SWORD: {
				Stats.StatRef.ATTACK: [5, 8]
			},
			WeaponResource.Type.AXE: {
				Stats.StatRef.ATTACK: [8, 12]
			}
		},
		Item.ItemType.CHEST: {
			Stats.StatRef.HEALTH: [1, 3],
			Stats.StatRef.DEFENSE: [1, 3],
			Stats.StatRef.MAGIC_DEFENSE: [1, 1]
		},
		Item.ItemType.HELMET: {
			Stats.StatRef.DEFENSE: [1, 3],
		},
		Item.ItemType.BOOTS: {
			Stats.StatRef.DEFENSE: [1, 3],
			Stats.StatRef.SPEED: [1, 2],
		},
		Item.ItemType.GLOVES: {
			Stats.StatRef.DEFENSE: [1, 3],
		},
		Item.ItemType.RING: {
			Stats.StatRef.MAGIC_DEFENSE: [1, 3],
		},
		Item.ItemType.AMULET: {
			Stats.StatRef.MAGIC_DEFENSE: [1, 3],
		},
	},
	"tier_2": {
		Item.ItemType.WEAPON: {
			WeaponResource.Type.SWORD: {
				Stats.StatRef.ATTACK: [7, 11]
			},
			WeaponResource.Type.AXE: {
				Stats.StatRef.ATTACK: [11, 15]
			}
		},
		Item.ItemType.CHEST: {
			Stats.StatRef.HEALTH: [2, 4],
			Stats.StatRef.DEFENSE: [2, 4],
			Stats.StatRef.MAGIC_DEFENSE: [2, 4]
		},
		Item.ItemType.HELMET: {
			Stats.StatRef.DEFENSE: [2, 4],
		},
		Item.ItemType.BOOTS: {
			Stats.StatRef.DEFENSE: [2, 4],
			Stats.StatRef.SPEED: [1, 2],
		},
		Item.ItemType.GLOVES: {
			Stats.StatRef.DEFENSE: [2, 4],
		},
		Item.ItemType.RING: {
			Stats.StatRef.MAGIC_DEFENSE: [2, 4],
		},
		Item.ItemType.AMULET: {
			Stats.StatRef.MAGIC_DEFENSE: [2, 4],
		},
	}
}
