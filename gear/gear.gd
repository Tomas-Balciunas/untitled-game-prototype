@abstract
extends Item
class_name Gear

enum Quality { POOR, COMMON, UNCOMMON, RARE, EXCEPTIONAL }

@export var base_stats: Stats
@export var modifiers: Array[StatModifier] = []
@export var effects: Array[Effect] = []
@export var quality: Quality = Quality.COMMON

@abstract
func get_applicable_stat_modifiers() -> Array[Stats.StatRef]

@abstract
func _build_instance() -> Variant
