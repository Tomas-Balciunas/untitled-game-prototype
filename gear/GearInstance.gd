extends ItemInstance
class_name GearInstance

var enhancement_level: int = 0

var effects: Array[Effect] = []
var modifiers: Array[StatModifier] = []

var extra_modifiers: Array[StatModifier] = []
var extra_effects: Array[Effect] = []

func get_base_stats() -> Dictionary:
	return {
		Stats.Stat.ATTACK: template.base_attack,
		Stats.Stat.HEALTH: template.base_health,
		Stats.Stat.SPEED: template.base_speed,
		Stats.Stat.MANA: template.base_mana,
		Stats.Stat.DEFENSE: template.base_defense,
		Stats.Stat.MAGIC_POWER: template.base_magic_power,
		Stats.Stat.DIVINE_POWER: template.base_divine_power,
		Stats.Stat.MAGIC_DEFENSE: template.base_magic_defense,
		Stats.Stat.RESISTANCE: template.base_resistance,
	}

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
