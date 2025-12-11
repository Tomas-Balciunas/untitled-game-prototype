extends RefCounted
class_name ItemConfig


static func get_accuracy(tier: String, weapon_type: WeaponResource.Type) -> int:
	if not ACCURACY.has(tier):
		push_error("item config error accuracy not found")
		return 0
	
	if not ACCURACY[tier].has(weapon_type):
		push_error("item config error accuracy not found")
		return 0
	
	return ACCURACY[tier][weapon_type]


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
		push_error("item config error stat range not found")
		return {}
	
	if not STAT_RANGE[tier].has(type):
		push_error("item config error stat range not found")
		return {}
	
	if not STAT_RANGE[tier][type].has(weapon_type):
		push_error("item config error stat range not found")
		return {}
	
	return STAT_RANGE[tier][type][weapon_type]


const ACCURACY: Dictionary = {
	"tier_1": {
		WeaponResource.Type.SWORD: 5,
		WeaponResource.Type.AXE: 8
	},
	"tier_2": {
		WeaponResource.Type.SWORD: 5,
		WeaponResource.Type.AXE: 8
	}
}

const MAX_MODIFIERS: Dictionary = {
	"tier_1": {
		Item.ItemType.WEAPON: {
			WeaponResource.Type.SWORD: 1,
			WeaponResource.Type.AXE: 1,
		}
	},
	"tier_2": {
		Item.ItemType.WEAPON: {
			WeaponResource.Type.SWORD: 1,
			WeaponResource.Type.AXE: 1,
		}
	}
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
		}
	},
	"tier_2": {
		Item.ItemType.WEAPON: {
			WeaponResource.Type.SWORD: {
				Stats.StatRef.ATTACK: [7, 11]
			},
			WeaponResource.Type.AXE: {
				Stats.StatRef.ATTACK: [11, 15]
			}
		}
	}
}
