extends Item

class_name Gear

@export var base_attack: int = 0
@export var base_health: int = 0
@export var base_speed: int = 0
@export var base_mana: int = 0
@export var base_defense: int = 0
@export var base_magic_power: int = 0
@export var base_divine_power: int = 0
@export var base_magic_defense: int = 0
@export var base_resistance: int = 0

@export var modifiers: Array[StatModifier]
@export var effects: Array[Effect]
