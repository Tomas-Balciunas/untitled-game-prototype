extends Job

class_name PriestClass

var stat_attribute_modifiers: Dictionary = {
	Stats.StatRef.ATTACK: {
		Attributes.STR: 0.5,
		Attributes.DEX: 0.1
	},
	Stats.StatRef.HEALTH: {
		Attributes.VIT: 2.0,
		Attributes.PIE: 0.4
	},
	Stats.StatRef.MANA: {
		Attributes.IQ: 0.2
	},
	Stats.StatRef.SP: {
		Attributes.IQ: 0.2
	},
	Stats.StatRef.SPEED: {
		Attributes.SPD: 1.0,
		Attributes.DEX: 0.3
	},
	Stats.StatRef.DEFENSE: {
		Attributes.VIT: 1.0,
		Attributes.DEX: 0.2
	},
	Stats.StatRef.MAGIC_POWER: {
		Attributes.IQ: 0.3
	},
	Stats.StatRef.DIVINE_POWER: {
		Attributes.PIE: 2
	},
	Stats.StatRef.MAGIC_DEFENSE: {
		Attributes.VIT: 0.5,
		Attributes.PIE: 0.3
	},
	Stats.StatRef.RESISTANCE: {
		Attributes.PIE: 0.5
	}
}

func get_stat_attribute_modifiers(st: Stats.StatRef) -> Dictionary:
	var entry: Dictionary = stat_attribute_modifiers.get(st, null)
	
	if entry:
		return entry
			
	return {}
