class_name ItemTypes


enum ItemType {
	EQUIPMENT,
	CONSUMABLE,
	QUEST
}

enum GearType {
	WEAPON,
	CHEST,
	HELMET,
	BOOTS,
	GLOVES,
	RING,
	AMULET,
}

enum Quality { POOR, COMMON, UNCOMMON, RARE, EXCEPTIONAL }

enum WeaponType {
	SWORD,
	AXE
}


static func gear_type_to_string(gear_type: ItemTypes.GearType) -> String:
	var names := {
		ItemTypes.GearType.WEAPON: "Weapon",
		ItemTypes.GearType.CHEST:  "Chestpiece",
		ItemTypes.GearType.HELMET: "Helmet",
		ItemTypes.GearType.BOOTS:  "Boots",
		ItemTypes.GearType.GLOVES: "Gloves",
		ItemTypes.GearType.RING:   "Ring",
		ItemTypes.GearType.AMULET: "Amulet",
	}
	return names.get(gear_type, "Unknown")


static func item_type_to_string(item_type: ItemTypes.ItemType) -> String:
	var names := {
		ItemTypes.ItemType.EQUIPMENT:  "Equipment",
		ItemTypes.ItemType.CONSUMABLE: "Consumable",
		ItemTypes.ItemType.QUEST:      "Quest Item"
	}
	return names.get(item_type, "Unknown")


static func weapon_type_to_string(weapon_type: ItemTypes.WeaponType) -> String:
	var names := {
		ItemTypes.WeaponType.SWORD: "Sword",
		ItemTypes.WeaponType.AXE:   "Axe",
	}
	return names.get(weapon_type, "Weapon")


static func quality_to_string(q: ItemTypes.Quality) -> String:
	match q:
		ItemTypes.Quality.POOR:        return "Poor"
		ItemTypes.Quality.COMMON:      return "Common"
		ItemTypes.Quality.UNCOMMON:    return "Uncommon"
		ItemTypes.Quality.RARE:        return "Rare"
		ItemTypes.Quality.EXCEPTIONAL: return "Exceptional"
	return "Unknown"
