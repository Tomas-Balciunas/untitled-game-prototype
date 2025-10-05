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

@export var health_growth: float = 0
@export var mana_growth: float = 0
@export var attack_growth: float = 0
@export var defense_growth: float = 0
@export var speed_growth: float = 0
@export var magic_power_growth: float = 0
@export var divine_power_growth: float = 0
@export var magic_defense_growth: float = 0
@export var resistance_growth: float = 0
