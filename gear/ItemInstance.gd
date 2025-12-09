@abstract
class_name ItemInstance

var id: String
var item_name: String
var item_description: String
var type: Item.ItemType


func item_type_to_string(item_type: Item.ItemType) -> String:
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

@abstract
func game_save() -> Dictionary

@abstract
func game_load() -> void
