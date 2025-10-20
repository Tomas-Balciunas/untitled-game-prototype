extends Job

class_name PriestClass

var stat_attribute_modifiers: Dictionary = {
	Stats.ATTACK: {
		Attributes.STR: 0.5,
		Attributes.DEX: 0.1
	},
	Stats.HEALTH: {
		Attributes.VIT: 2.0,
		Attributes.PIE: 0.4
	},
	Stats.MANA: {
		Attributes.IQ: 0.2
	},
	Stats.SPEED: {
		Attributes.SPD: 1.0,
		Attributes.DEX: 0.3
	},
	Stats.DEFENSE: {
		Attributes.VIT: 1.0,
		Attributes.DEX: 0.2
	},
	Stats.MAGIC_POWER: {
		Attributes.IQ: 0.3
	},
	Stats.DIVINE_POWER: {
		Attributes.PIE: 2
	},
	Stats.MAGIC_DEFENSE: {
		Attributes.VIT: 0.5,
		Attributes.PIE: 0.3
	},
	Stats.RESISTANCE: {
		Attributes.PIE: 0.5
	}
}

func get_stat_attribute_modifiers(st: String) -> Dictionary:
	var entry: Dictionary = stat_attribute_modifiers.get(st, null)
	
	if entry:
		return entry
			
	return {}
