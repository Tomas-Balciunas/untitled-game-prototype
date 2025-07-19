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
@export var priority: int = 0 # reserved for future sorting if needed

func compute_value(character: CharacterInstance) -> float:
	# Default: return the static value
	return value
