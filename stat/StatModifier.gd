extends Resource
class_name StatModifier

enum Type {
	ADDITIVE,
	MULTIPLICATIVE
}

@export var id: String
@export var name: String
@export var description: String
@export var stat: Stats.StatRef
@export var type: Type = Type.ADDITIVE
@export var value: float = 0.0
@export var priority: int = 0
@export var applicable_items: Array[Gear.ItemType] = []

func compute_value(_character: CharacterInstance, _derived_stat: float) -> float:
	if type == Type.ADDITIVE:
		return value
	else:
		return _derived_stat * value


func get_modifier_name() -> String:
	var suffix: String = "+" if value >= 0 else "-"
	return "%s%s" % [Stats.get_stat_name(stat), suffix]


func get_description() -> String:
	var suffix: String
	if type == Type.ADDITIVE:
		suffix = " +%s" % roundi(value)
	else:
		suffix = "%s%%" % roundi(value * 100)
	return "%s (%s)" % [Stats.get_stat_name(stat), suffix]
