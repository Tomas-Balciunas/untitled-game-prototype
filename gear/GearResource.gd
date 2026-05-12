@abstract
extends ItemResource
class_name GearResource

@export var base_stats: Stats
@export var modifiers: Array[StatModifier] = []
@export var effects: Array[Effect] = []
@export var quality: ItemTypes.Quality = ItemTypes.Quality.COMMON

@abstract
func get_applicable_stat_modifiers() -> Array[Stats.StatRef]

@abstract
func _build_instance() -> Variant
