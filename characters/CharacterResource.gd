extends BaseCharacterResource

class_name CharacterResource

const DEFAULT_STATS_PATH := "uid://57fo0cycgjne"
const DEFAULT_STAT_GROWTH_PATH := "uid://s8gs3fa65s30"

var is_main: bool = false

@export var attributes: Attributes

@export var level: int = 1
@export var slot_width: int = 1
@export var default_skills: Array[Skill] = []
@export var level_rewards: Array[LevelReward] = []
@export var default_effects: Array[Effect] = []
@export var default_damage_type: DamageTypes.Type
@export var default_items: Array[ItemResource] = []
@export var unequippable_gear: Array[ItemTypes.GearType] = []

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
	for entry in level_rewards:
		if entry.level == lvl:
			return entry.skills
	
	return []

func get_effects_for_level(lvl: int) -> Array[Effect]:
	for entry in level_rewards:
		if entry.level == lvl:
			return entry.effects
	
	return []

func get_skills_until_level(lvl: int) -> Array[Skill]:
	var entries: Array[Skill] = []
	
	for entry in level_rewards:
		if entry.level <= lvl:
			entries.append_array(entry.skills)
		
	return entries

func get_effects_until_level(lvl: int) -> Array[Effect]:
	var entries: Array[Effect] = []
	
	for entry in level_rewards:
		if entry.level <= lvl:
			entries.append_array(entry.effects)
		
	return entries

func get_stat_level_growth() -> Stats:
	if !stat_level_growth:
		push_error("Stat growth missing for %s" % name)
		
		return load(DEFAULT_STAT_GROWTH_PATH)
	
	return stat_level_growth
