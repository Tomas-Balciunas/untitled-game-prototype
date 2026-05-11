@abstract
extends Resource

class_name ItemResource

enum ItemType {
	GEAR,
	CONSUMABLE,
	QUEST
}

@export var id: String
@export var name: String
@export var type: ItemType
@export var description: String
@export var icon: Texture2D


@abstract
func _init() -> void


@abstract
func _build_instance() -> Variant


static func item_type_to_string(item_type: ItemResource.ItemType) -> String:
	var names := {
		ItemResource.ItemType.GEAR: "Equipment",
		ItemResource.ItemType.CONSUMABLE: "Consumable",
		ItemResource.ItemType.QUEST: "Quest Item"
	}
	return names.get(item_type, "Unknown")
