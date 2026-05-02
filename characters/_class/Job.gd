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
@export var stat_level_growth: Stats
var level_skills: Dictionary = {}
var level_effects: Dictionary = {}


func get_stat_attribute_growth(_st: Stats.StatRef) -> Dictionary:
	return {}

func get_stat_level_growth() -> Stats:
	if !stat_level_growth:
		push_error("Stat growth missing for %s" % name)

		return DEFAULT_STAT_GROWTH

	return stat_level_growth

func get_skills_for_level(lvl: int) -> Array:
	var entries = level_skills.get(lvl, null)
	
	if entries:
		return entries
		
	return []

func get_effects_for_level(lvl: int) -> Array:
	var entries = level_effects.get(lvl, null)
	
	if entries:
		return entries
	
	return []
	
