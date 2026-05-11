@abstract
class_name Item

var id: String
var item_name: String
var item_description: String
var type: ItemResource.ItemType


func get_item_name() -> String:
	return item_name


func item_type_to_string(item_type: ItemResource.ItemType) -> String:
	var names := {
		ItemResource.ItemType.GEAR: "Equipment",
		ItemResource.ItemType.CONSUMABLE: "Consumable",
		ItemResource.ItemType.QUEST: "Quest ItemResource"
	}
	return names.get(item_type, "Unknown")

@abstract
func game_save() -> Dictionary

@abstract
func game_load(data: Dictionary) -> void
