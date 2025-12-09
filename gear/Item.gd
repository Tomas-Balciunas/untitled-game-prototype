extends Resource

class_name Item

enum ItemType {
	WEAPON,
	CHEST,
	HELMET,
	BOOTS,
	GLOVES,
	RING,
	AMULET,
	CONSUMABLE,
	QUEST
}

@export var id: String
@export var name: String
@export var type: ItemType
@export var description: String
@export var icon: Texture2D


static func item_type_to_string(item_type: Item.ItemType) -> String:
	var names := {
		Item.ItemType.WEAPON: "Weapon",
		Item.ItemType.CHEST: "Chest Armor",
		Item.ItemType.HELMET: "Helmet",
		Item.ItemType.BOOTS: "Boots",
		Item.ItemType.GLOVES: "Gloves",
		Item.ItemType.RING: "Ring",
		Item.ItemType.AMULET: "Amulet",
		Item.ItemType.CONSUMABLE: "Consumable",
		Item.ItemType.QUEST: "Quest Item"
	}
	return names.get(item_type, "Unknown")
