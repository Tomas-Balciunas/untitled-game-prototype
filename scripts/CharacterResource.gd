extends BaseCharacterResource

class_name CharacterResource

const DEFAULT_RACE   = preload("res://characters/_race/_Unknown.tres")
const DEFAULT_JOB    = preload("res://characters/_class/_Unknown.tres")
const DEFAULT_GENDER = preload("res://characters/_gender/_Unknown.tres")
const DEFAULT_ATTRIBUTES = preload("res://characters/_attribute/_Unknown.tres")

const DEFAULT_EXPERIENCE_MANAGER := preload("res://scripts/experience/ExperienceManager.tres")

var is_main: bool = false

@export var race: Race = DEFAULT_RACE
@export var job: Job = DEFAULT_JOB
@export var gender: Gender = DEFAULT_GENDER

@export var attributes: Attributes = DEFAULT_ATTRIBUTES

@export var experience: int = 0
@export var slot_width: int = 1
@export var default_skills: Array[Skill] = []
@export var level_skills: Dictionary[int, Skill] = {}
@export var default_effects: Array[Effect] = []
@export var level_effects: Dictionary[int, Effect] = {}
@export var default_damage_type: DamageTypes.Type
@export var default_items: Array[Item] = []

@export var base_stats: Dictionary = Stats.STATS
@export var stat_level_growth: Dictionary = Stats.STATS


@export var battle_events: Array[BattleEvent]
@export var experience_manager: ExperienceManager = DEFAULT_EXPERIENCE_MANAGER

func get_stat_level_growth(stat: String) -> float:
	return stat_level_growth.get(stat, 0.0)

func get_skill_for_level(lvl: int) -> Skill:
	return level_skills.get(lvl, null)
	
func get_effect_for_level(lvl: int) -> Effect:
	return level_skills.get(lvl, null)
	
