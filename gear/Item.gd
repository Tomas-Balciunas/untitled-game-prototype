@abstract
class_name Item

var id: String
var item_name: String
var item_description: String
var type: ItemTypes.ItemType


func get_item_name() -> String:
	return item_name


func item_type_to_string(item_type: ItemTypes.ItemType) -> String:
	return ItemTypes.item_type_to_string(item_type)

@abstract
func game_save() -> Dictionary

@abstract
func game_load(data: Dictionary) -> void
