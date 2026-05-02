extends BaseCharacterResource

class_name CharacterResource

const DEFAULT_RACE   = preload("res://characters/_race/_Unknown.tres")
const DEFAULT_JOB    = preload("res://characters/_class/_Unknown.tres")
const DEFAULT_EXPERIENCE_MANAGER := preload("res://scripts/experience/ExperienceManager.tres")
const DEFAULT_STATS = preload("uid://57fo0cycgjne")
const DEFAULT_STAT_GROWTH = preload("uid://s8gs3fa65s30")

var is_main: bool = false

@export var race: Race = DEFAULT_RACE
@export var job: Job = DEFAULT_JOB

@export var attributes: Attributes

@export var experience: int = 0
@export var slot_width: int = 1
@export var default_skills: Array[Skill] = []
@export var level_skills: Dictionary = {}
@export var default_effects: Array[Effect] = []
@export var level_effects: Dictionary = {}
@export var default_damage_type: DamageTypes.Type
@export var default_items: Array[Item] = []

@export var base_stats: Stats = DEFAULT_STATS
@export var stat_level_growth: Stats

@export var battle_events: Array[BattleEvent]
@export var experience_manager: ExperienceManager = DEFAULT_EXPERIENCE_MANAGER

func _init() -> void:
	if not attributes:
		attributes = Attributes.new()
	
	if not base_stats:
		base_stats = Stats.new()
	
	if not stat_level_growth:
		stat_level_growth = Stats.new()

func get_skills_for_level(lvl: int) -> Array[Skill]:
	var entry = level_skills.get(lvl, null)
	if entry is Array:
		return entry as Array[Skill]
	if entry is Skill:
		return [entry] as Array[Skill]
	return []

func get_effects_for_level(lvl: int) -> Array[Effect]:
	var entry = level_effects.get(lvl, null)
	if entry is Array:
		return entry as Array[Effect]
	if entry is Effect:
		return [entry] as Array[Effect]
	return []

func get_stat_level_growth() -> Stats:
	if !stat_level_growth:
		push_error("Stat growth missing for %s" % name)
		
		return DEFAULT_STAT_GROWTH
	
	return stat_level_growth
