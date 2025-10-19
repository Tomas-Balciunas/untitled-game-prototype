extends Item

class_name Gear

@export var base_stats: Dictionary = Stats.STATS.duplicate()

@export var modifiers: Array[StatModifier]
@export var effects: Array[Effect]
