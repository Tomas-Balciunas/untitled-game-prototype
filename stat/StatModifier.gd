extends Resource
class_name StatModifier

enum Type {
	ADDITIVE,
	MULTIPLICATIVE
}

@export var name: String
@export var description: String
@export var attribute: Stats.Stat = Stats.Stat.ATTACK
@export var type: Type = Type.ADDITIVE
@export var value: float = 0.0
@export var priority: int = 0

func compute_value(_character: CharacterInstance) -> float:
	return value

func get_description() -> String:
	var suffix: String
	if type == Type.ADDITIVE:
		suffix = "+%s" % roundi(value)
	else:
		suffix = "%s%%" % roundi(value * 100)
	return "%s (%s)" % [description, suffix]
