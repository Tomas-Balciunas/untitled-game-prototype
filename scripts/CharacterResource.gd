extends BaseCharacterResource

class_name CharacterResource

const DEFAULT_RACE_PATH := "res://characters/_race/_Unknown.tres"
const DEFAULT_JOB_PATH := "res://characters/_class/_Unknown.tres"
const DEFAULT_STATS_PATH := "uid://57fo0cycgjne"
const DEFAULT_STAT_GROWTH_PATH := "uid://s8gs3fa65s30"

var is_main: bool = false

@export var race: Race = load(DEFAULT_RACE_PATH)
@export var job: Job = load(DEFAULT_JOB_PATH)

@export var attributes: Attributes

@export var level: int = 1
@export var slot_width: int = 1
@export var default_skills: Array[Skill] = []
@export var level_skills: Dictionary = {}
@export var default_effects: Array[Effect] = []
@export var level_effects: Dictionary = {}
@export var default_damage_type: DamageTypes.Type
@export var default_items: Array[ItemResource] = []

@export var base_stats: Stats = load(DEFAULT_STATS_PATH)
@export var stat_level_growth: Stats
@export var stat_attribute_growth: StatAttributeGrowth

@export var ai_behaviour: AiBehaviour = null
@export var battle_events: Array[BattleEvent]

@export var experience_granted: int = 1

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
		
		return load(DEFAULT_STAT_GROWTH_PATH)
	
	return stat_level_growth
