extends ItemInstance
class_name GearInstance

var enhancement_level: int = 0

var stats: Dictionary = Stats.STATS

var effects: Array[Effect] = []
var modifiers: Array[StatModifier] = []

var extra_modifiers: Array[StatModifier] = []
var extra_effects: Array[Effect] = []

func _init(resource: Gear) -> void:
	template = resource
	stats = resource.base_stats
	effects = resource.effects
	modifiers = resource.modifiers

func get_base_stats() -> Dictionary:
	return template.base_stats

func get_all_modifiers() -> Array[StatModifier]:
	var mods: Array[StatModifier] = []
	mods.append_array(modifiers)
	mods.append_array(extra_modifiers)
	
	return mods

func get_all_effects() -> Array[Effect]:
	var mods: Array[Effect] = []
	mods.append_array(effects)
	mods.append_array(extra_effects)
	
	return mods
