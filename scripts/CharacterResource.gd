extends BaseCharacterResource

class_name CharacterResource

const DEFAULT_RACE   = preload("res://characters/_race/_Unknown.tres")
const DEFAULT_JOB    = preload("res://characters/_class/_Unknown.tres")
const DEFAULT_GENDER = preload("res://characters/_gender/_Unknown.tres")
const DEFAULT_EXPERIENCE_MANAGER := preload("res://scripts/experience/ExperienceManager.tres")
const DEFAULT_STATS = preload("uid://57fo0cycgjne")
const DEFAULT_STAT_GROWTH = preload("uid://s8gs3fa65s30")

var is_main: bool = false

@export var race: Race = DEFAULT_RACE
@export var job: Job = DEFAULT_JOB
@export var gender: Gender = DEFAULT_GENDER

@export var attributes: Attributes

@export var experience: int = 0
@export var slot_width: int = 1
@export var default_skills: Array[Skill] = []
@export var level_skills: Dictionary[int, Skill] = {}
@export var default_effects: Array[Effect] = []
@export var level_effects: Dictionary[int, Effect] = {}
@export var default_damage_type: DamageTypes.Type
@export var default_items: Array[Item] = []

@export var base_stats: Stats = DEFAULT_STATS
@export var stat_level_growth: Stats = DEFAULT_STAT_GROWTH

@export var battle_events: Array[BattleEvent]
@export var experience_manager: ExperienceManager = DEFAULT_EXPERIENCE_MANAGER

func _init() -> void:
	if not attributes:
		attributes = Attributes.new()
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not stat_level_growth:
		stat_level_growth = Stats.new()

func get_skill_for_level(lvl: int) -> Skill:
	return level_skills.get(lvl, null)
	
func get_effect_for_level(lvl: int) -> Effect:
	return level_skills.get(lvl, null)
	
