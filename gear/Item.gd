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


static func create_from_save(data: Dictionary) -> Item:
	var cls_name: String = data.get("class", "")
	if cls_name == "Consumable":
		var c := Consumable.new()
		c.game_load(data)
		return c
	return Gear.create_from_save(data)
