extends Resource
class_name ItemInstance

@export var template: Item

func get_item_name() -> String:
	return template.name

func item_type_to_string(item_type: Item.ItemType) -> String:
	var names := {
		Item.ItemType.WEAPON: "Weapon",
		Item.ItemType.CHEST: "Chest Armor",
		Item.ItemType.HELMET: "Helmet",
		Item.ItemType.BOOTS: "Boots",
		Item.ItemType.GLOVES: "Gloves",
		Item.ItemType.RING: "Ring",
		Item.ItemType.CONSUMABLE: "Consumable",
		Item.ItemType.QUEST: "Quest Item"
	}
	return names.get(item_type, "Unknown")
