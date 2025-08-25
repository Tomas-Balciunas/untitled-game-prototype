extends Resource

class_name Item

enum ItemType {
	WEAPON,
	CHEST,
	HELMET,
	BOOTS,
	GLOVES,
	RING,
	CONSUMABLE,
	QUEST
}

@export var id: String
@export var name: String
@export var type: ItemType
@export var description: String
@export var icon: Texture2D
