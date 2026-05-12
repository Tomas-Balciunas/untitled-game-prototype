@abstract
extends Resource

class_name ItemResource

@export var id: String
@export var name: String
@export var type: ItemTypes.ItemType
@export var description: String
@export var icon: Texture2D


@abstract
func _init() -> void


@abstract
func _build_instance() -> Variant
