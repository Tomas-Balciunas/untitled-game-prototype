extends Resource
class_name EncounterEnemy

@export var resource: CharacterResource
@export var level: int = 1
@export var stat_modifiers: Array[StatModifier] = []
@export var extra_effects: Array[Effect] = []
@export var experience_multiplier: float = 1.0
@export var name_override: String = ""
