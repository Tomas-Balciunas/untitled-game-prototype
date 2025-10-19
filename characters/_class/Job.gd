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
@export var stat_level_growth: Dictionary = Stats.STATS

func get_stat_level_growth(stat: String) -> float:
	return stat_level_growth.get(stat, 0.0)
	
func get_stat_attribute_modifiers(_st: String) -> Dictionary:
	return {}
