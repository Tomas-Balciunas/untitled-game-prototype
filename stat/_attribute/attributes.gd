extends Resource

class_name Attributes

enum AttributeRef {
	STR,
	IQ,
	PIE,
	VIT,
	DEX,
	SPD,
	LUK
}

const STR = "STR"
const IQ = "IQ"
const PIE = "PIE"
const VIT = "VIT"
const DEX = "DEX"
const SPD = "SPD"
const LUK = "LUK"

@export var strength: int = 0
@export var intelligence: int = 0
@export var piety: int = 0
@export var vitality: int = 0
@export var dexterity: int = 0
@export var speed: int = 0
@export var luck: int = 0

func add(other: Attributes) -> void:
	strength += other.strength
	intelligence += other.intelligence
	piety += other.piety
	vitality += other.vitality
	dexterity += other.dexterity
	speed += other.speed
	luck += other.luck

static func to_str(value: int) -> String:
	return AttributeRef.keys()[value]

func get_attribute(attr: String) -> int:
	match attr:
		STR: return strength
		IQ: return intelligence
		PIE: return piety
		VIT: return vitality
		DEX: return dexterity
		SPD: return speed
		LUK: return luck
		_: return 0

func game_save() -> Dictionary:
	return {
		STR: strength,
		IQ: intelligence,
		PIE: piety,
		VIT: vitality,
		DEX: dexterity,
		SPD: speed,
		LUK: luck
	}

func game_load(data: Dictionary) -> void:
	strength = data.get(STR, 0)
	intelligence = data.get(IQ, 0)
	piety = data.get(PIE, 0)
	vitality = data.get(VIT, 0)
	dexterity = data.get(DEX, 0)
	speed = data.get(SPD, 0)
	luck = data.get(LUK, 0)
