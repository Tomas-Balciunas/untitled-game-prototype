@abstract
class_name Item

var id: String
var item_name: String
var item_description: String
var type: ItemTypes.ItemType
var value: int = 0
var icon: Texture2D


func get_item_name() -> String:
	return item_name

## Own icon if set, otherwise the type-based default (null if none exists).
func get_icon() -> Texture2D:
	return icon if icon != null else ItemIcons.for_item(self)

func get_item_description() -> String:
	return item_description

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
