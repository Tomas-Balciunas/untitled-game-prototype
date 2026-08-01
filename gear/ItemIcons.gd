extends RefCounted
class_name ItemIcons

const WEAPON_DEFAULTS := {
	ItemTypes.WeaponType.SWORD: "res://assets/icons/gear/weapons/1h_sword/1h-sword-default.png",
	ItemTypes.WeaponType.AXE: "res://assets/icons/gear/weapons/1h_axe/1h-axe-default-kra-test.png"
}

const GEAR_DEFAULTS := {}

const CONSUMABLE_DEFAULT := ""
const QUEST_DEFAULT := ""


static func for_item(item: Item) -> Texture2D:
	if item == null:
		return null
	if item is Weapon:
		return _load(WEAPON_DEFAULTS.get((item as Weapon).weapon_type, ""))
	if item is Gear:
		return _load(GEAR_DEFAULTS.get((item as Gear).get_gear_type(), ""))
	match item.type:
		ItemTypes.ItemType.CONSUMABLE: return _load(CONSUMABLE_DEFAULT)
		ItemTypes.ItemType.QUEST:      return _load(QUEST_DEFAULT)
	return null


static func _load(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
