extends Resource
class_name StatModifier

enum Type {
	ADDITIVE,
	MULTIPLICATIVE
}

@export var name: String
@export var attribute: String # "attack", "health", "mana", "speed"
@export var type: Type = Type.ADDITIVE
@export var value: float = 0.0
@export var priority: int = 0

func compute_value(_character: CharacterInstance) -> float:
	return value
