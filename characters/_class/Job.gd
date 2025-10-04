extends Resource

class_name Job

enum Name {
	FIGHTER,
	KNIGHT,
	MAGE,
	PRIEST,
	THIEF,
	UNKNOWN
}

@export var name: Name = Name.UNKNOWN
@export var attributes: Attributes
@export var skills: Array[Skill]
@export var effects: Array[Effect]

@export var attribute_modifiers: Dictionary = {
	Attributes.STR: 1,
	Attributes.IQ: 1,
	Attributes.PIE: 1,
	Attributes.VIT: 1,
	Attributes.DEX: 1,
	Attributes.SPD: 1,
	Attributes.LUK: 1
}

@export var stat_per_level: Dictionary = {
	Stats.Stat.HEALTH: 1,
	Stats.Stat.MANA: 1,
}
