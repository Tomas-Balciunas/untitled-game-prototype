extends Resource

class_name Race

enum Name {
	HUMAN,
	ELF,
	DWARF,
	BEAST
}

@export var name: Name
@export var attributes: Attributes
