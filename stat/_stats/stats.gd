extends Resource
class_name Stats

enum StatRef {
	ATTACK,
	HEALTH,
	MANA,
	SP,
	ACTION_POINTS,
	SPEED,
	DEFENSE,
	MAGIC_POWER,
	DIVINE_POWER,
	MAGIC_DEFENSE,
	RESISTANCE,
	ACCURACY,
	EVASION,
	HEALING_DONE,
	HEALING_RECEIVED
}

const PERCENTAGE_BASE := 100.0

const PERCENTAGE_STATS: Array[StatRef] = [
	StatRef.HEALING_DONE,
	StatRef.HEALING_RECEIVED,
]

static func is_percentage_stat(stat: StatRef) -> bool:
	return stat in PERCENTAGE_STATS

const STAT_NAMES := {
	StatRef.ATTACK:        "Attack",
	StatRef.HEALTH:        "Health",
	StatRef.MANA:          "Mana",
	StatRef.SP:            "SP",
	StatRef.ACTION_POINTS: "Action Points",
	StatRef.SPEED:         "Speed",
	StatRef.DEFENSE:       "Defense",
	StatRef.MAGIC_POWER:   "Magic Power",
	StatRef.DIVINE_POWER:  "Divine Power",
	StatRef.MAGIC_DEFENSE: "Magic Defense",
	StatRef.RESISTANCE:    "Resistance",
	StatRef.ACCURACY:      "Accuracy",
	StatRef.EVASION:       "Evasion",
	StatRef.HEALING_DONE:  "Healing Done",
	StatRef.HEALING_RECEIVED: "Healing Received"
}

@export var attack: float = 0.0
@export var health: float = 0.0
@export var mana: float = 0.0
@export var sp: float = 0.0
@export var action_points: float = 0.0
@export var speed: float = 0.0
@export var defense: float = 0.0
@export var magic_power: float = 0.0
@export var divine_power: float = 0.0
@export var magic_defense: float = 0.0
@export var resistance: float = 0.0
@export var accuracy: float = 0.0
@export var evasion: float = 0.0
@export var healing_done: float = 0.0
@export var healing_received: float = 0.0


func add(other: Stats) -> void:
	attack            += other.attack
	health            += other.health
	mana              += other.mana
	sp                += other.sp
	speed             += other.speed
	action_points     += other.action_points
	defense           += other.defense
	magic_power       += other.magic_power
	divine_power      += other.divine_power
	magic_defense     += other.magic_defense
	resistance        += other.resistance
	accuracy          += other.accuracy
	evasion           += other.evasion
	healing_done      += other.healing_done
	healing_received  += other.healing_received


func get_stat(stat: StatRef) -> int:
	match stat:
		StatRef.ATTACK:        return roundi(attack)
		StatRef.HEALTH:        return roundi(health)
		StatRef.MANA:          return roundi(mana)
		StatRef.SP:            return roundi(sp)
		StatRef.ACTION_POINTS: return roundi(action_points)
		StatRef.SPEED:         return roundi(speed)
		StatRef.DEFENSE:       return roundi(defense)
		StatRef.MAGIC_POWER:   return roundi(magic_power)
		StatRef.DIVINE_POWER:  return roundi(divine_power)
		StatRef.MAGIC_DEFENSE: return roundi(magic_defense)
		StatRef.RESISTANCE:    return roundi(resistance)
		StatRef.ACCURACY:      return roundi(accuracy)
		StatRef.EVASION:       return roundi(evasion)
		StatRef.HEALING_DONE:     return roundi(healing_done)
		StatRef.HEALING_RECEIVED: return roundi(healing_received)
		_:                     return 0


func set_stat(stat: StatRef, value: float) -> void:
	match stat:
		StatRef.ATTACK:        attack        = value
		StatRef.HEALTH:        health        = value
		StatRef.MANA:          mana          = value
		StatRef.SP:            sp            = value
		StatRef.ACTION_POINTS: action_points = value
		StatRef.SPEED:         speed         = value
		StatRef.DEFENSE:       defense       = value
		StatRef.MAGIC_POWER:   magic_power   = value
		StatRef.DIVINE_POWER:  divine_power  = value
		StatRef.MAGIC_DEFENSE: magic_defense = value
		StatRef.RESISTANCE:    resistance    = value
		StatRef.ACCURACY:      accuracy      = value
		StatRef.EVASION:       evasion       = value
		StatRef.HEALING_DONE:     healing_done     = value
		StatRef.HEALING_RECEIVED: healing_received = value


func add_stat(stat: StatRef, value: float) -> void:
	match stat:
		StatRef.ATTACK:        attack        += value
		StatRef.HEALTH:        health        += value
		StatRef.MANA:          mana          += value
		StatRef.SP:            sp            += value
		StatRef.ACTION_POINTS: action_points += value
		StatRef.SPEED:         speed         += value
		StatRef.DEFENSE:       defense       += value
		StatRef.MAGIC_POWER:   magic_power   += value
		StatRef.DIVINE_POWER:  divine_power  += value
		StatRef.MAGIC_DEFENSE: magic_defense += value
		StatRef.RESISTANCE:    resistance    += value
		StatRef.ACCURACY:      accuracy      += value
		StatRef.EVASION:       evasion       += value
		StatRef.HEALING_DONE:     healing_done     += value
		StatRef.HEALING_RECEIVED: healing_received += value


static func get_stat_name(stat: StatRef) -> String:
	return STAT_NAMES[stat]


func game_save() -> Dictionary:
	return {
		"attack": attack, "health": health, "mana": mana,
		"action_points": action_points, "sp": sp, "speed": speed,
		"defense": defense, "magic_power": magic_power, 
		"divine_power": divine_power, "magic_defense": magic_defense,
		"resistance": resistance, "accuracy": accuracy, "evasion": evasion,
		"healing_done": healing_done, "healing_received": healing_received,
	}


func game_load(data: Dictionary) -> void:
	attack        = data.get("attack", 0.0)
	health        = data.get("health", 0.0)
	mana          = data.get("mana", 0.0)
	action_points = data.get("action_points", 0.0)
	sp            = data.get("sp", 0.0)
	speed         = data.get("speed", 0.0)
	defense       = data.get("defense", 0.0)
	magic_power   = data.get("magic_power", 0.0)
	divine_power  = data.get("divine_power", 0.0)
	magic_defense = data.get("magic_defense", 0.0)
	resistance    = data.get("resistance", 0.0)
	accuracy      = data.get("accuracy", 0.0)
	evasion       = data.get("evasion", 0.0)
	healing_done     = data.get("healing_done", 0.0)
	healing_received = data.get("healing_received", 0.0)
