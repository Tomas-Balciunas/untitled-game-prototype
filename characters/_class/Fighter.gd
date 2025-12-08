extends Job

class_name FighterClass

func _init() -> void:
	level_skills = {
		2: load("uid://cneghh04ud4gg"),
		5: load("uid://d2u72es2eig6a")
	}

var stat_attribute_modifiers: Dictionary = {
	Stats.StatRef.ATTACK: {
		Attributes.STR: 1.0,
		Attributes.DEX: 0.5
	},
	Stats.StatRef.HEALTH: {
		Attributes.VIT: 1.0,
		Attributes.PIE: 0.2
	},
	Stats.StatRef.MANA: {
		Attributes.IQ: 0.5
	},
	Stats.StatRef.SP: {
		Attributes.DEX: 0.5
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
		Attributes.PIE: 0.2
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
