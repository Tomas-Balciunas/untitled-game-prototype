extends Resource
class_name Stats

enum StatRef {
	ATTACK,
	HEALTH,
	MANA,
	SP,
	SPEED,
	DEFENSE,
	MAGIC_POWER,
	DIVINE_POWER,
	MAGIC_DEFENSE,
	RESISTANCE,
	ACCURACY,
	EVASION,
}

const STAT_NAMES := {
	StatRef.ATTACK:        "Attack",
	StatRef.HEALTH:        "Health",
	StatRef.MANA:          "Mana",
	StatRef.SP:            "SP",
	StatRef.SPEED:         "Speed",
	StatRef.DEFENSE:       "Defense",
	StatRef.MAGIC_POWER:   "Magic Power",
	StatRef.DIVINE_POWER:  "Divine Power",
	StatRef.MAGIC_DEFENSE: "Magic Defense",
	StatRef.RESISTANCE:    "Resistance",
	StatRef.ACCURACY:      "Accuracy",
	StatRef.EVASION:       "Evasion",
}

@export var attack: float = 0
@export var health: float = 0
@export var mana: float = 0
@export var sp: float = 0
@export var speed: float = 0
@export var defense: float = 0
@export var magic_power: float = 0
@export var divine_power: float = 0
@export var magic_defense: float = 0
@export var resistance: float = 0
@export var accuracy: float = 0
@export var evasion: float = 0

func add(other: Stats) -> void:
	attack        += other.attack
	health        += other.health
	mana          += other.mana
	sp            += other.sp
	speed         += other.speed
	defense       += other.defense
	magic_power   += other.magic_power
	divine_power  += other.divine_power
	magic_defense += other.magic_defense
	resistance    += other.resistance
	accuracy      += other.accuracy
	evasion       += other.evasion

func get_stat(stat: StatRef) -> int:
	match stat:
		StatRef.ATTACK:        return round(attack)
		StatRef.HEALTH:        return round(health)
		StatRef.MANA:          return round(mana)
		StatRef.SP:            return round(sp)
		StatRef.SPEED:         return round(speed)
		StatRef.DEFENSE:       return round(defense)
		StatRef.MAGIC_POWER:   return round(magic_power)
		StatRef.DIVINE_POWER:  return round(divine_power)
		StatRef.MAGIC_DEFENSE: return round(magic_defense)
		StatRef.RESISTANCE:    return round(resistance)
		StatRef.ACCURACY:      return round(accuracy)
		StatRef.EVASION:       return round(evasion)
		_:                     return 0

func set_stat(stat: StatRef, value: float) -> void:
	match stat:
		StatRef.ATTACK:        attack        = value
		StatRef.HEALTH:        health        = value
		StatRef.MANA:          mana          = value
		StatRef.SP:            sp            = value
		StatRef.SPEED:         speed         = value
		StatRef.DEFENSE:       defense       = value
		StatRef.MAGIC_POWER:   magic_power   = value
		StatRef.DIVINE_POWER:  divine_power  = value
		StatRef.MAGIC_DEFENSE: magic_defense = value
		StatRef.RESISTANCE:    resistance    = value
		StatRef.ACCURACY:      accuracy      = value
		StatRef.EVASION:       evasion       = value

func add_stat(stat: StatRef, value: float) -> void:
	match stat:
		StatRef.ATTACK:        attack        += value
		StatRef.HEALTH:        health        += value
		StatRef.MANA:          mana          += value
		StatRef.SP:            sp            += value
		StatRef.SPEED:         speed         += value
		StatRef.DEFENSE:       defense       += value
		StatRef.MAGIC_POWER:   magic_power   += value
		StatRef.DIVINE_POWER:  divine_power  += value
		StatRef.MAGIC_DEFENSE: magic_defense += value
		StatRef.RESISTANCE:    resistance    += value
		StatRef.ACCURACY:      accuracy      += value
		StatRef.EVASION:       evasion       += value

static func get_stat_name(stat: StatRef) -> String:
	return STAT_NAMES[stat]


func game_save() -> Dictionary:
	return {
		"attack": attack, "health": health, "mana": mana,
		"sp": sp, "speed": speed, "defense": defense,
		"magic_power": magic_power, "divine_power": divine_power,
		"magic_defense": magic_defense, "resistance": resistance,
		"accuracy": accuracy, "evasion": evasion,
	}


func game_load(data: Dictionary) -> void:
	attack        = data.get("attack", 0)
	health        = data.get("health", 0)
	mana          = data.get("mana", 0)
	sp            = data.get("sp", 0)
	speed         = data.get("speed", 0)
	defense       = data.get("defense", 0)
	magic_power   = data.get("magic_power", 0)
	divine_power  = data.get("divine_power", 0)
	magic_defense = data.get("magic_defense", 0)
	resistance    = data.get("resistance", 0)
	accuracy      = data.get("accuracy", 0)
	evasion       = data.get("evasion", 0)
