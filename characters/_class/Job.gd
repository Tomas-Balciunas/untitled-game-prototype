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

const DEFAULT_STAT_GROWTH = preload("uid://s8gs3fa65s30")

@export var name: Name = Name.UNKNOWN
@export var attributes: Attributes
@export var skills: Array[Skill]
@export var effects: Array[Effect]
@export var stat_level_growth: Stats = DEFAULT_STAT_GROWTH
var level_skills: Dictionary[int, Skill] = {}
var level_effects: Dictionary[int, Effect] = {}


func get_stat_attribute_modifiers(_st: Stats.StatRef) -> Dictionary:
	return {}

func get_skill_for_level(lvl: int) -> Skill:
	return level_skills.get(lvl, null)
	
func get_effect_for_level(lvl: int) -> Effect:
	return level_effects.get(lvl, null)
	
	
