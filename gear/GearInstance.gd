@abstract
extends ItemInstance
class_name GearInstance

var enhancement_level: int = 0

var quality: int = 1

var stats: Stats
var base_stats: Stats

var base_effects: Array[Effect] = []
var base_modifiers: Array[StatModifier] = []

var extra_modifiers: Array[StatModifier] = []
var extra_effects: Array[Effect] = []


func get_base_stats() -> Stats:
	return base_stats

func get_all_modifiers() -> Array[StatModifier]:
	return base_modifiers + extra_modifiers

func get_all_effects() -> Array[Effect]:
	return base_effects + extra_effects
