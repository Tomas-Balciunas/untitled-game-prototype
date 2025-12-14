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
	RESISTANCE
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
}

@export var attack: int = 0
@export var health: int = 0
@export var mana: int = 0
@export var sp: int = 0
@export var speed: int = 0
@export var defense: int = 0
@export var magic_power: int = 0
@export var divine_power: int = 0
@export var magic_defense: int = 0
@export var resistance: int = 0

func add(other: Stats) -> void:
	attack += other.attack
	health += other.health
	mana += other.mana
	sp += other.sp
	speed += other.speed
	defense += other.defense
	magic_power += other.magic_power
	divine_power += other.divine_power
	magic_defense += other.magic_defense
	resistance += other.resistance

func get_stat(stat: StatRef) -> int:
	match stat:
		StatRef.ATTACK:        return attack
		StatRef.HEALTH:        return health
		StatRef.MANA:          return mana
		StatRef.SP:            return sp
		StatRef.SPEED:         return speed
		StatRef.DEFENSE:       return defense
		StatRef.MAGIC_POWER:   return magic_power
		StatRef.DIVINE_POWER:  return divine_power
		StatRef.MAGIC_DEFENSE: return magic_defense
		StatRef.RESISTANCE:    return resistance
		_:                     return 0

func set_stat(stat: StatRef, value: float) -> void:
	match stat:
		StatRef.ATTACK:        attack = int(value)
		StatRef.HEALTH:        health = int(value)
		StatRef.MANA:          mana = int(value)
		StatRef.SP:            sp = int(value)
		StatRef.SPEED:         speed = int(value)
		StatRef.DEFENSE:       defense = int(value)
		StatRef.MAGIC_POWER:   magic_power = int(value)
		StatRef.DIVINE_POWER:  divine_power = int(value)
		StatRef.MAGIC_DEFENSE: magic_defense = int(value)
		StatRef.RESISTANCE:    resistance = int(value)

func add_stat(stat: StatRef, value: float) -> void:
	match stat:
		StatRef.ATTACK:        attack += int(value)
		StatRef.HEALTH:        health += int(value)
		StatRef.MANA:          mana += int(value)
		StatRef.SP:            sp += int(value)
		StatRef.SPEED:         speed += int(value)
		StatRef.DEFENSE:       defense += int(value)
		StatRef.MAGIC_POWER:   magic_power += int(value)
		StatRef.DIVINE_POWER:  divine_power += int(value)
		StatRef.MAGIC_DEFENSE: magic_defense += int(value)
		StatRef.RESISTANCE:    resistance += int(value)

static func get_stat_name(stat: StatRef) -> String:
	return STAT_NAMES[stat]
