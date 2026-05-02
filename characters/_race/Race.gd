extends Resource

class_name Race

enum Name {
	HUMAN,
	ELF,
	DWARF,
	BEAST,
	UNKNOWN
}

@export var name: Name = Name.UNKNOWN
@export var attributes: Attributes
@export var stat_attribute_growth: StatAttributeGrowth
