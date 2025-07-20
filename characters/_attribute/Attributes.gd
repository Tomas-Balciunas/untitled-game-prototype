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

@export var str: int = 1
@export var iq: int = 1
@export var pie: int = 1
@export var vit: int = 1
@export var dex: int = 1
@export var spd: int = 1
@export var luk: int = 1

func add(other: Attributes) -> void:
	str += other.str
	iq += other.iq
	pie += other.pie
	vit += other.vit
	dex += other.dex
	spd += other.spd
	luk += other.luk

static func to_str(value: int) -> String:
	return AttributeRef.keys()[value]
