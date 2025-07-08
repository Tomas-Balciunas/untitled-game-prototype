extends Object

class_name DamageTypes

enum Type {
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	POISON,
	HOLY,
	DARK
}

static func to_str(value: int) -> String:
	return Type.keys()[value]
